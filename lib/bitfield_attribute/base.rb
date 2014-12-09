require 'active_model'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/object/inclusion'
require 'active_support/concern'
require 'active_record/connection_adapters/column'

module BitfieldAttribute
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def define_bits(*keys)
        if @keys.present?
          raise ArgumentError, 'Define all your bits with a single #define_bits statement'
        end

        @keys = keys.map(&:to_sym)

        if @keys.uniq.size != @keys.size
          raise ArgumentError, "Bit names are not uniq"
        end

        if @keys.size > INTEGER_SIZE
          raise ArgumentError, "Too many bit names for #{INTEGER_SIZE}-bit integer"
        end

        define_bit_methods
      end

      def keys
        @keys
      end

      private
      def define_bit_methods
        keys.each do |key|
          define_setter(key)
          define_getter(key)
        end
      end

      def define_setter(key)
        define_method :"#{key}=" do |value|
          @values[key] = value
          write_bits
        end
      end

      def define_getter(key)
        define_method :"#{key}?" do
          @values[key] || false
        end

        alias_method key, :"#{key}?"
      end
    end

    def initialize(instance, attribute)
      @instance = instance
      @attribute = attribute

      keys = self.class.keys

      @values = keys.zip([false] * keys.size)
      @values = Hash[@values]

      read_bits
    end

    def to_a
      @values.map { |key, value| key if value }.compact
    end

    def value
      @instance[@attribute].to_i
    end

    def attributes
      @values.freeze
    end

    def attributes=(hash)
      @values.each { |key, _| @values[key] = false }
      update(hash)
    end

    def update(hash)
      hash.symbolize_keys.each do |key, value|
        if @values.keys.include?(key)
          @values[key] = true_value?(value)
        end
      end

      write_bits
    end

    private
    def read_bits
      bit_value = @instance[@attribute].to_i

      @values.keys.each.with_index do |name, index|
        bit = 2 ** index
        @values[name] = true if bit_value & bit == bit
      end
    end

    def write_bits
      0.tap do |bits|
        @values.keys.each.with_index do |name, index|
          bits = bits | (2 ** index) if @values[name]
        end

        @instance[@attribute] = bits
      end
    end

    def true_value?(value)
      value.in?(ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES)
    end

    INTEGER_SIZE = 32
  end
end
