require 'git'

module Cease
  class Git
    def self.log
      new.log
    end

    def initialize(pwd: Pathname.pwd.to_s)
      @pwd = pwd
    end

    def log
      @log ||= ::Git.open(pwd).log
    end

    private

    attr_reader :pwd
  end
end
