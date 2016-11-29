# Rouge Lexer for Fvwm 2.6.x config files (fvwm2rc)

module Rouge
  module Lexers
    class Fvwm < RegexLexer
      title 'fvwm'
      desc 'Lexes fvwm2rc config files'

      tag 'fvwm'
      aliases 'fvwm2rc'
      filenames '*.fvwm2rc'

      def self.analyze_text(text)
        return 1   if text.start_with?('AddToFunc ')
        return 1   if text.start_with?('AddToMenu ')
        return 1   if text.start_with?('Style ')
      end

      # Command type lists:
      # Highlight: Keyword
      Command = %w(
        Silent Beep Nop RaiseLower KeepRc
      ).join('|')

      # Highlight: Keyword Name
      CommandName = %w(
        DestroyFunc DestroyMenu InfoStoreRemove DestroyDecor UnsetEnv
        AddToDecor AddToMenu AddToFunc
      ).join('|')

      # Highlight: Keyword Name String
      CommandNameString = %w(
        InfoStoreAdd SetEnv
      ).join('|')

      # Highlight: Keyword :input
      CommandInput = %w(
        Exec PipeRead Break Raise WindowShade Maximize Iconify FlipFocus
        Focus State Title Refresh Restart Quit WindowList Close Delete
        Destroy Stick Resize Move Lower Layer MoveToDesk Echo MoveThreshold
        DesktopName DesktopSize EdgeScroll EdgeResistance EdgeThickness
        EwmhBaseStruts DefaultFont OpaqueMoveSize HideGeometryWindow XorValue
        IgnoreModifiers ClickTime MoveThreshold GotoDesk ImagePath
        DefaultColorset StrokeFunc WarpToWindow Schedule Deschedule MoveToPage
        BugOpts Read GotoDeskAndPage WindowList Read AnimatedMove Wait
      ).join('|')

      # Highlight: Keyword Name :input
      CommandNameInput = %w(
        SendToModule Module Menu Function KillModule Popup Mouse Colorset
        Key
      ).join('|')

      # Conditionals
      # Highlight: Keyword (Conditions)
      Conditionals = %w(
        Test TestRc Current All ThisWindow Next Prev Any None Pick WindowList
        PointerWindow
      ).join('|')

      # Styles
      # Highlight: Keyword :styles
      StyleString = %w(
        Style MenuStyle Colorset
      ).join('|')

      # Decors
      DecorTriggers = %w(
        ButtonStyle AddToButtonStyle TitleStyle AddToTitleStyle BorderStyle
      ).join('|')

      DecorStates = %w(
        ActiveUp ActiveDown Active InactiveUp InactiveDown State
        Inactive ToggledActiveUp ToggledActiveDown ToggledActive
        ToggledInactiveUp ToggledInactiveDown ToggledInactive
        AllNormal AllToggled AllActive AllInactive AllUp AllDown
        AllActiveUp AllActiveDown AllIncativeUp AllInactiveDown
      ).join('|')

      DecorStyles = %w(
        MultiPixmap Pixmap AdjustedPixmap ShrunkPixmap
        StretchedPixmap TiledPixmap HGradient VGradient
        \?Gradient DGradient BGradient SGradient CGradient
        RGradient YGradient Colorset Solid Simple Default
        Vector MiniIcon Centered LeftJustified Height
        RightJustified MinHeight Style
      ).join('|')

      DecorNames = %w(
        Main LeftMain RightMain UnderText LeftButtons Buttons
        LeftEnd LeftOfText RightOfText RightEnd RightButtons
      ).join('|')

      DecorFlags = %w(
        Flat Raised Sunk UseTitleStyle UseBorderStyle Flag
        MwmDecorMax MwmDecorMin MwmDecorStick MwmDecorLayer
        MwmDecorMenu MwmDecorStick Clear HiddenHandles NoInset
      ).join('|')



      state :strings do
        rule /\$\[[a-zA-Z0-9*_\-.]+\]/, Name::Variable
        rule /\$[a-zA-Z0-9*_\-.]+/, Name::Variable
      end

      state :commands do
        rule /(#{Command}|#{CommandName}|#{CommandInput})\n/i, Keyword
        rule /(#{Command})\s+/i, Keyword
        rule /(#{CommandName})(\s+\S+)/i do |m|
          groups Keyword, Name
        end
        rule /(#{CommandNameString})(\s+\S+)(.*\n)/i do |m|
          groups Keyword, Name, Literal::String
        end
        rule /(#{CommandInput})\s+/i, Keyword, :input
        rule /(#{CommandNameInput})(\s+\S+\n)/i do |m|
          groups Keyword, Name
        end
        rule /(#{CommandNameInput})(\s+\S+\s+)/i do |m|
          groups Keyword, Name
          push :input
        end
      end

      state :commands_pop do
        rule /(#{Command}|#{CommandName}|#{CommandInput})\n/i, Keyword, :pop!
        rule /(#{CommandNameInput})(\s+\S+\n)/i do |m|
          groups Keyword, Name
          pop!
        end
        rule /(#{Command})\s+/i, Keyword
        rule /(#{CommandName})(\s+\S+)/i do |m|
          groups Keyword, Name
        end
        rule /(#{CommandNameString})(\s+\S+)(.*\n)/i do |m|
          groups Keyword, Name, Literal::String
        end
        rule /(#{CommandInput})\s+/i, Keyword
        rule /(#{CommandNameInput})(\s+\S+\s+)/i do |m|
          groups Keyword, Name
        end
      end


      # Root (main) state
      state :root do
        rule /#.*$\n?/, Comment
        rule /\\/, Text
        rule /\s+/, Text

        mixin :strings

        # Styles
        rule /(#{StyleString})(\s+)("[^"\n]+")/i do |m|
          groups Keyword, Text, Literal::String
          push :styles
        end
        rule /(#{StyleString})(\s+)('[^'\n]+')/i do |m|
          groups Keyword, Text, Literal::String
          push :styles
        end
        rule /(#{StyleString})(\s+)(\S+)/i do |m|
          groups Keyword, Text, Literal::String
          push :styles
        end
        rule /WindowStyle\s+/i, Keyword, :styles

        # Conditionals
        rule /(#{Conditionals})(\s+\()/i do |m|
          groups Keyword, Text
          push :conditions
        end
        rule /(#{Conditionals})\s+/i, Keyword

        # Decors
        rule /(\+\s+)?(ButtonStyle\s+)(\S+)(\s+-\s+)/i do |m|
          groups Text, Keyword, Name, Keyword
          push :decor3
        end
        rule /(\+\s+)?(ButtonStyle|AddButtonStyle)(\s+\S+\s+)/i do |m|
          groups Text, Keyword, Name
          push :decor
        end
        rule /(\+\s+)?(#{DecorTriggers})(\s+)/i do |m|
          groups Text, Keyword, Text
          push :decor
        end

        # Functions
        rule /(AddToFunc\s+)(\S+\s+)([ICDHM]\s+)/i do |m|
          groups Keyword, Name, Literal::String
        end
        rule /(\+\s+)([ICDHM]\s+)/i do |m|
          groups Text, Literal::String
        end

        # Menus
        rule /(AddToMenu\s+)(\S+\s*\n)/i do |m|
          groups Keyword, Name
        end
        rule /(AddToMenu\s+)(\S+\s+)/i do |m|
          groups Keyword, Name
          push :menuitem
        end
        rule /\+\s+/, Text, :menuitem

        # Bindings
        rule /(Key|Mouse)(\s+)(\(.+\))(\s+\S+\s+)(\S+\s+\S+)/i do |m|
          groups Keyword, Text, Literal::String, Name, Literal::String::Other
        end
        rule /(Key|Mouse)(\s+\S+\s+)(\S+\s+\S+)/i do |m|
          groups Keyword, Name, Literal::String::Other
        end
        rule /(Stroke\s+)(\(.+\))(\s+\S+)(\s+\S+\s+)(\S+\s+\S+)/i do |m|
          groups Keyword, Literal::String, Literal::String::Other,
            Name, Literal::String::Other
        end
        rule /(Stroke)(\s+\S+)(\s+\S+\s+)(\S+\s+\S+)/i do |m|
          groups Keyword, Literal::String::Other, Name, Literal::String::Other
        end

        # Modules
        rule /(DestroyModuleConfig\s+)([^:]+)(:\s*)(\S+\s*\n)/i do |m|
          groups Keyword, Name::Entity, Text, Literal::String::Other
        end
        rule /(\*[a-zA-Z0-9\-$]+:\s+)(\()/ do |m|
          groups Name::Entity, Text
          push :buttons
        end
        rule /(\*[a-zA-Z0-9\-$]+:\s+)(\S+)/ do |m|
          groups Name::Entity, Keyword
          push :input
        end

        # Commands
        mixin :commands

        # No Match - Generic: Name :input
        rule /\S+/, Name, :input
      end

      # Style state. Highlights comma separated list as
      # Keyword String.Other for each item in the list.
      # Should use a list of known styles, menustyles and
      # colorsets (todo).
      state :styles do
        rule /\\\n/, Text
        rule /\s*\n/, Text, :pop!
        rule /,\s*/, Text
        rule /\s+/, Text
        rule /(!?[a-zA-Z0-9]*)([^,\n]*)/ do |m|
          groups Keyword::Type, Literal::String::Other
        end
      end

      # Input state.
      state :input do
        rule /\\\n/, Text
        rule /\n/, Text, :pop!
        rule /\s+/, Text
        rule /["\'()]/, Text
        mixin :strings
        mixin :commands_pop
        rule /[^\n\s$\\"\'()]+/, Literal::String::Other
      end

      # Conditions
      state :conditions do
        rule /\\\n/, Text
        rule /\s*\n/, Text, :pop!
        rule /\)/, Text, :pop!
        rule /,\s*/, Text
        rule /\s+/, Text
        rule /!?[a-zA-Z0-9]+/, Name::Attribute, :input_conditions
      end
      state :input_conditions do
        rule /\\\n/, Text
        rule /\s*\n/, Text, :root
        rule /\)/, Text, :root
        rule /,/, Text, :pop!
        rule /\s+/, Text
        mixin :strings
        rule /[^,)\n$]+/, Literal::String::Other
      end

      # Menu Item
      state :menuitem do
        rule /\s/, Text, :pop!
        rule /"/, Literal::String, :menuitemquote1
        rule /'/, Literal::String, :menuitemquote2
        rule /[^&%*\s$]+/, Literal::String
        rule /&/, Literal::String::Other
        rule /%.*%/, Literal::String::Other
        rule /\*.*\*/, Literal::String::Other
        mixin :strings
      end
      state :menuitemquote1 do
        rule /"/, Literal::String, :root
        rule /[^&%*$"]+/, Literal::String
        rule /&/, Literal::String::Other
        rule /%.*%/, Literal::String::Other
        rule /\*.*\*/, Literal::String::Other
        mixin :strings
      end
      state :menuitemquote2 do
        rule /'/, Literal::String, :root
        rule /[^&%*$']+/, Literal::String
        rule /&/, Literal::String::Other
        rule /%.*%/, Literal::String::Other
        rule /\*.*\*/, Literal::String::Other
        mixin :strings
      end

      # Decors
      state :decor do
        rule /\\\n/, Text
        rule /\n/, Text, :pop!
        rule /\)/, Text, :pop!
        rule /\s+/, Text
        rule /(#{DecorStates})\b/i, Literal::String
        rule /(#{DecorStyles})\b/i, Keyword::Type
        rule /(#{DecorNames})\b/i, Name
        rule /--/, Keyword, :decor2
        rule /-/, Literal::String::Other
        rule /\(/, Text, :push
        rule /[^\s()\-\n\\]+/, Literal::String::Other
      end
      state :decor2 do
        rule /\\\n/, Text
        rule /\)/, Text, :root
        rule /\n/, Text, :root
        rule /\s+/, Text
        rule /!?(#{DecorFlags})\b/i, Keyword::Type
        rule /[^\s)\n\\]+/, Literal::String::Other
      end
      state :decor3 do
        rule /\\\n/, Text
        rule /\n/, Text, :pop!
        rule /\s+/, Text
        rule /!?(#{DecorFlags})\b/i, Keyword::Type
        rule /[^\s\n\\]/, Literal::String::Other
      end

      # FvwmButtons
      state :buttons do
        rule /\\/, Text
        rule /\)/, Text, :pop!
        rule /,?\s+/, Text
        rule /\(/, Text, :nested_buttons
        mixin :strings
        rule /!?[a-zA-Z0-9]+/, Keyword, :inputbutton
      end
      state :inputbutton do
        rule /\\/, Text
        rule /\)/, Text, :root
        rule /,/, Text, :pop!
        rule /\s+/, Text
        rule /\(/, Text, :nested_buttons
        mixin :strings
        rule /[^,\)\n$]*/, Literal::String::Other
      end
      state :nested_buttons do
        rule /\)/, Text, :pop!
        rule /\s+/, Text
        rule /\(/, Text, :push
        mixin :strings
        rule /[^\)\n$]/, Literal::String::Other
      end

    end
  end
end
