class ArticleArchive
  extend Forwardable
  include Enumerable

  delegate [:current_page, :total_pages, :limit_value] => :articles

  attr_reader :day, :month, :page, :year, :locale

  def initialize(year:, month:, day: nil, page: 1, locale: nil)
    @year   = year
    @month  = month
    @page   = page
    @day    = day
    @locale = locale
  end

  def articles
    return @articles if defined?(@articles)

    @articles = Article.published.live.root.order(title: :desc)

    @articles = @articles.where(year:   year)   if year.present?
    @articles = @articles.where(month:  month)  if month.present?
    @articles = @articles.where(day:    day)    if day.present?
    @articles = @articles.where(locale: locale) if locale.present?

    @articles = @articles.page(page).per(15)
  end

  def calendar
    return @calendar if defined?(@calendar)

    @calendar = {}
    articles.each do |article|
      year  = article.published_at.year
      month = article.published_at.month

      @calendar[year]        = {} if @calendar[year].nil?
      @calendar[year][month] = [] if @calendar[year][month].nil?

      @calendar[year][month] << article
    end

    @calendar
  end

  def paginator
    @paginator ||= ArticleArchivePaginator.new(self)
  end

  def each(&block)
    calendar.sort.reverse.each(&block)
  end
end
