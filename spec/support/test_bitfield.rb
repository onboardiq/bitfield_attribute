class TestBitfield
  include BitfieldAttribute::Base
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  define_bits :first, :second, :last
end

module BitField
  class User
    class NotificationSettings
      extend ActiveModel::Naming
      extend ActiveModel::Translation

      include BitfieldAttribute::Base

      define_bits :second
    end
  end
end
