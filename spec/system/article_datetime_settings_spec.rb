require 'rails_helper'

describe 'Setting and changing an articles published_at date' do
  let(:admin) do
    create(:user, username: 'user1', password: 'c' * 31, role: 'publisher')
  end

  it 'creates a new article' do
    login_user(admin)
    visit '/admin/articles'

    click_on 'NEW'

    within '#publication_datetime' do
      execute_script("$('#publication_date').val('2018-12-24')")
      execute_script("$('#publication_time').val('11:59:00')")
      select('UTC', from: 'article_published_at_tz')
    end

    within('#publication_status') { choose 'Draft' }

    find_button('Save', match: :first).click

    expect(page).to have_content 'Article was successfully created'
    article = Article.first
    expect(article.published_at.utc).to eq('2018-12-24 11:59:00 UTC')
  end

  it 'updates an existing article' do
    article = create(:article, published_at: Time.zone.parse('2018-12-24 11:59:00 UTC'))
    expect(article.published_at.utc).to eq('2018-12-24 11:59:00 UTC')
    expect(article.published_at_tz).to eq('Pacific Time (US & Canada)')

    login_user(admin)
    visit '/admin/articles'

    click_on 'EDIT'
    within '#publication_datetime' do
      # make sure pre-fills are right
      expect(find_field('published_at_date').value).to eq '2018-12-24'
      expect(find_field('published_at_time').value).to eq '03:59:00'
      expect(find_field('article_published_at_tz').value).to eq 'Pacific Time (US & Canada)'

      execute_script("$('#publication_date').val('2018-12-26')")
      execute_script("$('#publication_time').val('22:59:00')")
      select('UTC', from: 'article_published_at_tz')
    end

    within('#publication_status') { choose 'Draft' }

    find_button('Save', match: :first).click

    expect(page).to have_content 'Article was successfully updated'
    expect(article.reload.published_at.utc).to eq('2018-12-26 22:59:00 UTC')
    expect(article.reload.published_at_tz).to eq('UTC')
  end

  it 'saves an article without entering publication date info' do
    login_user(admin)
    visit '/admin/articles'

    click_on 'NEW'

    within('#publication_status') { choose 'Draft' }

    find_button('Save', match: :first).click

    expect(page).to have_content 'Article was successfully created'
    article = Article.first
    expect(article.published_at).to be_nil
  end

  it 'uses ‘PUBLISH NOW’ feature', :js do
    # TODO: the 'publish now' feature relies on a JavaScript in
    # the front-end to automatically set the form fields and submit the
    # form. This makes testing time hard since we cannot
    # Timecop.freeze the front-end. Consider making the 'Publish Now!'
    # feature a back-end feature
    login_user(admin)
    visit '/admin/articles'

    click_on 'NEW'

    time = Time.now.utc

    within('#datetime') { click_on 'Publish NOW!' }

    expect(page).to have_content 'Article was successfully created'
    article = Article.last

    # rough approximation of 'now'
    expect(article.published_at.day).to eq(time.day)
    expect(article.published_at.month).to eq(time.month)
    expect(article.published_at.year).to eq(time.year)
    expect(article.published_at.hour).to eq(time.hour)
    expect(article).to be_published

    expect(article.reload.published_at_tz).to eq('UTC')
  end
end
