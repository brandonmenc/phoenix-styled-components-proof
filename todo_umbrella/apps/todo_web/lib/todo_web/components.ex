defmodule TodoWeb.Components do
  @moduledoc """
  Components are custom HTML tags with styles specified in code.

  Components are "*.exs" files in placed in the "APP_web/components" directory
  with the following format:

      # components/title.exs
      defmodule TodoWeb.Components.Title do
        use TodoWeb.Components.Component

        tag :h1

        style \"""
        color: DeepPink;
        font-weight: 600;
        \"""
      end

  The sub-modules here will compile the component files, generate unique
  CSS class names, write the styles to a file, expose component rendering
  functions to templates, and allow the use of capital letter HTML tags as a
  shortcut for calling those component rendering functions.

      # templates/example.html.eex
      <Title>Styled components in Phoenix</Title>

      <%= c :Title do %>
        Styled Components in Phoenix
      <% end %>

  """

  alias TodoWeb.Components

  defmodule Component do
    @moduledoc """
    Component DSL.

    Generates render and style output functions and a custom CSS class for
    a component at compile time.
    """

    def format_style(single_line_style) do
      single_line_style
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&"  #{&1}")
      |> Enum.join("\n")
    end

    defmacro tag(tag) do
      quote do
        @tag unquote(tag)
      end
    end

    defmacro style(style) do
      quote do
        @style unquote(style)
      end
    end

    defmacro __using__(_opts) do
      quote do
        import Components.Component

        @tag nil
        @style nil
        @class nil

        @before_compile Components.Component
      end
    end

    defmacro __before_compile__(_env) do
      # Generate CSS class
      component_name =
        __CALLER__.module
        |> Module.split()
        |> List.last()

      class = "psc-" <> component_name

      quote do
        @class unquote(class)

        def render(do: content) do
          Phoenix.HTML.Tag.content_tag(@tag, content, class: @class)
        end

        def compiled_style do
          ".#{@class} {\n#{format_style(@style)}\n}\n"
        end
      end
    end
  end

  defmodule Compiler do
    @moduledoc """
    Compiles a directory of components.

    Enumerates the components in the components directory "APP_web/components",
    compiles them, writes their styles to a single CSS file in "APP_web/assets",
    and defines render functions for each component in the `Components.ViewHelpers`
    module.

    Also monitors the components directory for changes that require recompilation.
    """

    @component_style_file Path.expand("../../assets/css/components.css", __DIR__)
    @components_path Path.expand("components", __DIR__)

    defp component_files do
      @components_path
      |> Path.join("*.exs")
      |> Path.wildcard()
    end

    defp compile_components do
      component_files()
      |> Enum.map(fn file ->
        [{module, _}] = Code.compile_file(file)
        {module, component_name(module)}
      end)
    end

    defp component_name(component_module) do
      component_module
      |> Module.split()
      |> List.last()
      |> String.to_atom()
    end

    defp init_component_style_file do
      if File.exists?(@component_style_file) do
        File.rm!(@component_style_file)
      end

      File.write!(
        @component_style_file,
        "/* generated at #{Time.utc_now()} */\n\n"
      )
    end

    defp write_component_style(component_module) do
      File.write!(
        @component_style_file,
        Kernel.apply(component_module, :compiled_style, []),
        [:append]
      )
    end

    def __phoenix_recompile__? do
      {:ok, %File.Stat{mtime: current_mtime}} = File.lstat(@components_path)
      last_mtime = Application.get_env(:phoenix, :components_mtime)

      Application.put_env(:phoenix, :components_mtime, current_mtime)

      if !last_mtime do
        false
      else
        last_mtime != current_mtime
      end
    end

    defmacro __before_compile__(_env) do
      init_component_style_file()

      for {module, _name} <- compile_components() do
        name = component_name(module)

        write_component_style(module)

        quote do
          def c(unquote(name), do: content) do
            unquote(module).render(do: content)
          end
        end
      end
    end
  end

  defmodule ViewHelpers do
    @moduledoc """
    View helpers for using components in templates.
    """

    @before_compile Components.Compiler
  end

  defmodule Engine do
    @moduledoc """
    Component-aware template engine.

    Pre-processes template files, replacing capital letter HTML tags with calls
    to the appropriate component rendering function before passing the template
    on to the standard Phoenix template engine.
    """

    @behaviour Phoenix.Template.Engine

    def compile(path, _name) do
      path
      |> read!()
      |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)
    end

    def read!(path) do
      path
      |> File.read!()
      |> precompile()
    end

    def replace(string, regex, replacement) do
      Regex.replace(regex, string, replacement)
    end

    def precompile(source) do
      component_open_tag = ~r/<(?<tag>[A-Z]\w*)(?<args>[^>]*)>/
      component_close_tag = ~r/<\/(?<tag>[A-Z]\w*)>/

      source
      |> replace(component_open_tag, "<%= c :\\1\\2 do %>")
      |> replace(component_close_tag, "<% end %>")
    end
  end
end
