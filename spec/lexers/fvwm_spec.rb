# -*- coding: utf-8 -*- #

describe Rouge::Lexers::Fvwm do
  let(:subject) { Rouge::Lexers::Fvwm.new }

  describe 'guessing' do
    include Support::Guessing

    it 'guesses by filename' do
      assert_guess :filename => 'foo.fvwm2rc'
    end

  end
end
