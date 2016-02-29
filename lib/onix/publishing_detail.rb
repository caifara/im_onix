module ONIX

  class SalesOutlet < Subset
    attr_accessor :identifier, :name
    def parse(n)
      n.children.each do |t|
        case t.name
          when "SalesOutletName"
            @name = t.text
          when "SalesOutletIdentifier"
            @identifier = Identifier.parse_identifier(t, "SalesOutlet")
        end
      end
    end
  end

  class SalesRestriction < Subset
    attr_accessor :type, :sales_outlets, :note, :start_date, :end_date

    def initialize
      @sales_outlets=[]
    end

    def parse(n)
      n.children.each do |t|
        case t.name
          when "SalesRestrictionType"
            @type = SalesRestrictionType.from_code(t.text)
          when "SalesOutlet"
            @sales_outlets << SalesOutlet.from_xml(t)
          when "SalesRestrictionNote"
            @note = t.text
          when "StartDate"
            fmt=t["dateformat"] || "00"
            @start_date=ONIX::Helper.to_date(fmt,t.text)
          when "EndDate"
            fmt=t["dateformat"] || "00"
            @end_date=ONIX::Helper.to_date(fmt,t.text)
        end
      end
    end

  end

  class SalesRights < Subset
    attr_accessor :type, :territory, :sales_restrictions

    def initialize
      @sales_restrictions=[]
    end

    def parse(n)
      n.children.each do |t|
        case t.name
          when "SalesRightsType"
            @type=SalesRightsType.from_code(t.text)
          when "Territory"
            @territory=Territory.from_xml(t)
          when "SalesRestriction"
            @sales_restrictions << SalesRestriction.from_xml(t)
        end
      end
    end
  end

  class PublishingDate < Subset
    attr_accessor :role, :date

    def parse(n)
      n.children.each do |t|
        case t.name
          when "PublishingDateRole"
            @role=PublishingDateRole.from_code(t.text)
        end
      end

      @date=OnixDate.from_xml(n)

    end
  end

  class PublishingDetail < Subset
    attr_accessor :status, :publishers, :imprints,
                  :sales_rights,
                  :publishing_dates

    def initialize
      @sales_rights=[]
      @publishing_dates=[]
    end

    def publisher
      if @publishers.length > 0
      if @publishers.length==1
        @publishers.first
      else
        raise ExpectsOneButHasSeveral, Publisher
      end
      else
        nil
      end
    end

    def imprint
      if @imprints.length > 0
      if @imprints.length==1
        @imprints.first
      else
        raise ExpectsOneButHasSeveral, Imprint
      end
      else
        nil
      end
    end

    def publication_date
      pub=@publishing_dates.select{|pd| pd.role.human=="PublicationDate" or pd.role.human=="PublicationDateOfPrintCounterpart" or pd.role.human=="EmbargoDate"}.first
      if pub
        pub.date.date
      else
        nil
      end
    end

    def parse(n)
      n.children.each do |t|
        case t.name
          when "PublishingStatus"
            @status=PublishingStatus.from_code(t.text)
          when "SalesRights"
            @sales_rights << SalesRights.from_xml(t)
          when "PublishingDate"
            @publishing_dates << PublishingDate.from_xml(t)
        end
      end


      @imprints = Imprint.parse_entities(n,"./Imprint")
      @publishers=Publisher.parse_entities(n,"./Publisher")
    end
  end
end