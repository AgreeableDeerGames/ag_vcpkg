#include "pch.h"

#include <vcpkg/base/system.debug.h>
#include <vcpkg/base/system.print.h>

#include <vcpkg/commands.h>
#include <vcpkg/globalstate.h>
#include <vcpkg/metrics.h>
#include <vcpkg/vcpkgcmdarguments.h>

namespace vcpkg
{
    static void set_from_feature_flag(const std::vector<std::string>& flags, StringView flag, Optional<bool>& place)
    {
        if (!place.has_value())
        {
            const auto not_flag = [flag](const std::string& el) {
                return !el.empty() && el[0] == '-' && flag == StringView{el.data() + 1, el.data() + el.size()};
            };

            if (std::find(flags.begin(), flags.end(), flag) != flags.end())
            {
                place = true;
            }
            if (std::find_if(flags.begin(), flags.end(), not_flag) != flags.end())
            {
                if (place.has_value())
                {
                    System::printf(
                        System::Color::error, "Error: both %s and -%s were specified as feature flags\n", flag, flag);
                    Metrics::g_metrics.lock()->track_property("error", "error feature flag +-" + flag.to_string());
                    Checks::exit_fail(VCPKG_LINE_INFO);
                }

                place = false;
            }
        }
    }

    static void parse_feature_flags(const std::vector<std::string>& flags, VcpkgCmdArguments& args)
    {
        // NOTE: when these features become default, switch the value_or(false) to value_or(true)
        struct FeatureFlag
        {
            StringView flag_name;
            Optional<bool>& local_option;
        };

        const FeatureFlag flag_descriptions[] = {
            {VcpkgCmdArguments::BINARY_CACHING_FEATURE, args.binary_caching},
            {VcpkgCmdArguments::MANIFEST_MODE_FEATURE, args.manifest_mode},
            {VcpkgCmdArguments::COMPILER_TRACKING_FEATURE, args.compiler_tracking},
        };

        for (const auto& desc : flag_descriptions)
        {
            set_from_feature_flag(flags, desc.flag_name, desc.local_option);
        }
    }

    static void parse_value(const std::string* arg_begin,
                            const std::string* arg_end,
                            StringView option_name,
                            std::unique_ptr<std::string>& option_field)
    {
        if (arg_begin == arg_end)
        {
            System::print2(System::Color::error, "Error: expected value after --", option_name, '\n');
            Metrics::g_metrics.lock()->track_property("error", "error option name");
            print_usage();
            Checks::exit_fail(VCPKG_LINE_INFO);
        }

        if (option_field != nullptr)
        {
            System::print2(System::Color::error, "Error: --", option_name, " specified multiple times\n");
            Metrics::g_metrics.lock()->track_property("error", "error option specified multiple times");
            print_usage();
            Checks::exit_fail(VCPKG_LINE_INFO);
        }

        option_field = std::make_unique<std::string>(*arg_begin);
    }

    static void parse_cojoined_value(StringView new_value,
                                     StringView option_name,
                                     std::unique_ptr<std::string>& option_field)
    {
        if (nullptr != option_field)
        {
            System::printf(System::Color::error, "Error: --%s specified multiple times\n", option_name);
            Metrics::g_metrics.lock()->track_property("error", "error option specified multiple times");
            print_usage();
            Checks::exit_fail(VCPKG_LINE_INFO);
        }

        option_field = std::make_unique<std::string>(new_value.begin(), new_value.end());
    }

    static void parse_switch(bool new_setting, StringView option_name, Optional<bool>& option_field)
    {
        if (option_field && option_field != new_setting)
        {
            System::print2(System::Color::error, "Error: conflicting values specified for --", option_name, '\n');
            Metrics::g_metrics.lock()->track_property("error", "error conflicting switches");
            print_usage();
            Checks::exit_fail(VCPKG_LINE_INFO);
        }
        option_field = new_setting;
    }

    static void parse_cojoined_multivalue(StringView new_value,
                                          StringView option_name,
                                          std::vector<std::string>& option_field)
    {
        if (new_value.size() == 0)
        {
            System::print2(System::Color::error, "Error: expected value after ", option_name, '\n');
            Metrics::g_metrics.lock()->track_property("error", "error option name");
            print_usage();
            Checks::exit_fail(VCPKG_LINE_INFO);
        }

        option_field.emplace_back(new_value.begin(), new_value.end());
    }

    static void parse_cojoined_list_multivalue(StringView new_value,
                                               StringView option_name,
                                               std::vector<std::string>& option_field)
    {
        if (new_value.size() == 0)
        {
            System::print2(System::Color::error, "Error: expected value after ", option_name, '\n');
            Metrics::g_metrics.lock()->track_property("error", "error option name");
            print_usage();
            Checks::exit_fail(VCPKG_LINE_INFO);
        }

        for (const auto& v : Strings::split(new_value, ','))
        {
            option_field.emplace_back(v.begin(), v.end());
        }
    }

    VcpkgCmdArguments VcpkgCmdArguments::create_from_command_line(const Files::Filesystem& fs,
                                                                  const int argc,
                                                                  const CommandLineCharType* const* const argv)
    {
        std::vector<std::string> v;
        for (int i = 1; i < argc; ++i)
        {
            std::string arg;
#if defined(_WIN32)
            arg = Strings::to_utf8(argv[i]);
#else
            arg = argv[i];
#endif
            // Response file?
            if (arg.size() > 0 && arg[0] == '@')
            {
                arg.erase(arg.begin());
                auto lines = fs.read_lines(fs::u8path(arg));
                if (!lines.has_value())
                {
                    System::print2(System::Color::error, "Error: Could not open response file ", arg, '\n');
                    Checks::exit_fail(VCPKG_LINE_INFO);
                }
                std::copy(lines.get()->begin(), lines.get()->end(), std::back_inserter(v));
            }
            else
            {
                v.emplace_back(std::move(arg));
            }
        }

        return VcpkgCmdArguments::create_from_arg_sequence(v.data(), v.data() + v.size());
    }

    // returns true if this does parse this argument as this option
    template<class T, class F>
    static bool try_parse_argument_as_option(StringView option, StringView arg, T& place, F parser)
    {
        if (arg.size() <= option.size() + 1)
        {
            // it is impossible for this argument to be this option
            return false;
        }

        if (Strings::starts_with(arg, "x-") && !Strings::starts_with(option, "x-"))
        {
            arg = arg.substr(2);
        }
        if (Strings::starts_with(arg, option) && arg.byte_at_index(option.size()) == '=')
        {
            parser(arg.substr(option.size() + 1), option, place);
            return true;
        }

        return false;
    }

    static bool equals_modulo_experimental(StringView arg, StringView option)
    {
        if (Strings::starts_with(arg, "x-") && !Strings::starts_with(option, "x-"))
        {
            return arg.substr(2) == option;
        }
        else
        {
            return arg == option;
        }
    }

    // returns true if this does parse this argument as this option
    template<class T>
    static bool try_parse_argument_as_switch(StringView option, StringView arg, T& place)
    {
        if (equals_modulo_experimental(arg, option))
        {
            parse_switch(true, option, place);
            return true;
        }

        if (Strings::starts_with(arg, "no-") && equals_modulo_experimental(arg.substr(3), option))
        {
            parse_switch(false, option, place);
            return true;
        }

        return false;
    }

    VcpkgCmdArguments VcpkgCmdArguments::create_from_arg_sequence(const std::string* arg_begin,
                                                                  const std::string* arg_end)
    {
        VcpkgCmdArguments args;
        std::vector<std::string> feature_flags;

        for (auto it = arg_begin; it != arg_end; ++it)
        {
            std::string basic_arg = *it;

            if (basic_arg.empty())
            {
                continue;
            }

            if (basic_arg.size() >= 2 && basic_arg[0] == '-' && basic_arg[1] != '-')
            {
                Metrics::g_metrics.lock()->track_property("error", "error short options are not supported");
                Checks::exit_with_message(VCPKG_LINE_INFO, "Error: short options are not supported: %s", basic_arg);
            }

            if (basic_arg.size() < 2 || basic_arg[0] != '-')
            {
                if (args.command.empty())
                {
                    args.command = std::move(basic_arg);
                }
                else
                {
                    args.command_arguments.push_back(std::move(basic_arg));
                }
                continue;
            }

            // make argument case insensitive before the first =
            auto first_eq = std::find(std::begin(basic_arg), std::end(basic_arg), '=');
            Strings::ascii_to_lowercase(std::begin(basic_arg), first_eq);
            // basic_arg[0] == '-' && basic_arg[1] == '-'
            StringView arg = StringView(basic_arg).substr(2);

            // command switch
            if (arg == VCPKG_ROOT_DIR_ARG)
            {
                ++it;
                parse_value(it, arg_end, VCPKG_ROOT_DIR_ARG, args.vcpkg_root_dir);
                continue;
            }
            if (arg == TRIPLET_ARG)
            {
                ++it;
                parse_value(it, arg_end, TRIPLET_ARG, args.triplet);
                continue;
            }

            constexpr static std::pair<StringView, std::unique_ptr<std::string> VcpkgCmdArguments::*>
                cojoined_values[] = {
                    {MANIFEST_ROOT_DIR_ARG, &VcpkgCmdArguments::manifest_root_dir},
                    {BUILDTREES_ROOT_DIR_ARG, &VcpkgCmdArguments::buildtrees_root_dir},
                    {DOWNLOADS_ROOT_DIR_ARG, &VcpkgCmdArguments::downloads_root_dir},
                    {INSTALL_ROOT_DIR_ARG, &VcpkgCmdArguments::install_root_dir},
                    {PACKAGES_ROOT_DIR_ARG, &VcpkgCmdArguments::packages_root_dir},
                    {SCRIPTS_ROOT_DIR_ARG, &VcpkgCmdArguments::scripts_root_dir},
                };

            constexpr static std::pair<StringView, std::vector<std::string> VcpkgCmdArguments::*>
                cojoined_multivalues[] = {
                    {OVERLAY_PORTS_ARG, &VcpkgCmdArguments::overlay_ports},
                    {OVERLAY_TRIPLETS_ARG, &VcpkgCmdArguments::overlay_triplets},
                    {BINARY_SOURCES_ARG, &VcpkgCmdArguments::binary_sources},
                };

            constexpr static std::pair<StringView, Optional<bool> VcpkgCmdArguments::*> switches[] = {
                {DEBUG_SWITCH, &VcpkgCmdArguments::debug},
                {DISABLE_METRICS_SWITCH, &VcpkgCmdArguments::disable_metrics},
                {SEND_METRICS_SWITCH, &VcpkgCmdArguments::send_metrics},
                {PRINT_METRICS_SWITCH, &VcpkgCmdArguments::print_metrics},
                {FEATURE_PACKAGES_SWITCH, &VcpkgCmdArguments::feature_packages},
                {BINARY_CACHING_SWITCH, &VcpkgCmdArguments::binary_caching},
                {WAIT_FOR_LOCK_SWITCH, &VcpkgCmdArguments::wait_for_lock},
            };

            bool found = false;
            for (const auto& pr : cojoined_values)
            {
                if (try_parse_argument_as_option(pr.first, arg, args.*pr.second, parse_cojoined_value))
                {
                    found = true;
                    break;
                }
            }
            if (found) continue;

            for (const auto& pr : cojoined_multivalues)
            {
                if (try_parse_argument_as_option(pr.first, arg, args.*pr.second, parse_cojoined_multivalue))
                {
                    found = true;
                    break;
                }
            }
            if (found) continue;

            if (try_parse_argument_as_option(FEATURE_FLAGS_ARG, arg, feature_flags, parse_cojoined_list_multivalue))
            {
                continue;
            }

            for (const auto& pr : switches)
            {
                if (try_parse_argument_as_switch(pr.first, arg, args.*pr.second))
                {
                    found = true;
                    break;
                }
            }
            if (found) continue;

            const auto eq_pos = std::find(arg.begin(), arg.end(), '=');
            if (eq_pos != arg.end())
            {
                const auto& key = StringView(arg.begin(), eq_pos);
                const auto& value = StringView(eq_pos + 1, arg.end());

                args.command_options[key.to_string()].push_back(value.to_string());
            }
            else
            {
                args.command_switches.insert(arg.to_string());
            }
        }

        parse_feature_flags(feature_flags, args);

        return args;
    }

    ParsedArguments VcpkgCmdArguments::parse_arguments(const CommandStructure& command_structure) const
    {
        bool failed = false;
        ParsedArguments output;

        const size_t actual_arg_count = command_arguments.size();

        if (command_structure.minimum_arity == command_structure.maximum_arity)
        {
            if (actual_arg_count != command_structure.minimum_arity)
            {
                System::printf(System::Color::error,
                               "Error: '%s' requires %u arguments, but %u were provided.\n",
                               this->command,
                               command_structure.minimum_arity,
                               actual_arg_count);
                failed = true;
            }
        }
        else
        {
            if (actual_arg_count < command_structure.minimum_arity)
            {
                System::printf(System::Color::error,
                               "Error: '%s' requires at least %u arguments, but %u were provided\n",
                               this->command,
                               command_structure.minimum_arity,
                               actual_arg_count);
                failed = true;
            }
            if (actual_arg_count > command_structure.maximum_arity)
            {
                System::printf(System::Color::error,
                               "Error: '%s' requires at most %u arguments, but %u were provided\n",
                               this->command,
                               command_structure.maximum_arity,
                               actual_arg_count);
                failed = true;
            }
        }

        auto switches_copy = this->command_switches;
        auto options_copy = this->command_options;

        const auto find_option = [](const auto& set, StringLiteral name) {
            auto it = set.find(name);
            if (it == set.end() && !Strings::starts_with(name, "x-"))
            {
                it = set.find(Strings::format("x-%s", name));
            }

            return it;
        };

        for (const auto& switch_ : command_structure.options.switches)
        {
            const auto it = find_option(switches_copy, switch_.name);
            if (it != switches_copy.end())
            {
                output.switches.insert(switch_.name);
                switches_copy.erase(it);
            }
            const auto option_it = find_option(options_copy, switch_.name);
            if (option_it != options_copy.end())
            {
                // This means that the switch was passed like '--a=xyz'
                System::printf(
                    System::Color::error, "Error: The option '--%s' does not accept an argument.\n", switch_.name);
                options_copy.erase(option_it);
                failed = true;
            }
        }

        for (const auto& option : command_structure.options.settings)
        {
            const auto it = find_option(options_copy, option.name);
            if (it != options_copy.end())
            {
                const auto& value = it->second;
                if (value.empty())
                {
                    Checks::unreachable(VCPKG_LINE_INFO);
                }

                if (value.size() > 1)
                {
                    System::printf(
                        System::Color::error, "Error: The option '%s' can only be passed once.\n", option.name);
                    failed = true;
                }
                else if (value.front().empty())
                {
                    // Fail when not given a value, e.g.: "vcpkg install sqlite3 --additional-ports="
                    System::printf(System::Color::error,
                                   "Error: The option '--%s' must be passed a non-empty argument.\n",
                                   option.name);
                    failed = true;
                }
                else
                {
                    output.settings.emplace(option.name, value.front());
                    options_copy.erase(it);
                }
            }
            const auto switch_it = find_option(switches_copy, option.name);
            if (switch_it != switches_copy.end())
            {
                // This means that the option was passed like '--a'
                System::printf(
                    System::Color::error, "Error: The option '--%s' must be passed an argument.\n", option.name);
                switches_copy.erase(switch_it);
                failed = true;
            }
        }

        for (const auto& option : command_structure.options.multisettings)
        {
            const auto it = find_option(options_copy, option.name);
            if (it != options_copy.end())
            {
                const auto& value = it->second;
                for (const auto& v : value)
                {
                    if (v.empty())
                    {
                        System::printf(System::Color::error,
                                       "Error: The option '--%s' must be passed non-empty arguments.\n",
                                       option.name);
                        failed = true;
                    }
                    else
                    {
                        output.multisettings[option.name].push_back(v);
                    }
                }
                options_copy.erase(it);
            }
            const auto switch_it = find_option(switches_copy, option.name);
            if (switch_it != switches_copy.end())
            {
                // This means that the option was passed like '--a'
                System::printf(
                    System::Color::error, "Error: The option '--%s' must be passed an argument.\n", option.name);
                switches_copy.erase(switch_it);
                failed = true;
            }
        }

        if (!switches_copy.empty())
        {
            System::printf(System::Color::error, "Unknown option(s) for command '%s':\n", this->command);
            for (auto&& switch_ : switches_copy)
            {
                System::print2("    '--", switch_, "'\n");
            }
            for (auto&& option : options_copy)
            {
                System::print2("    '--", option.first, "'\n");
            }
            System::print2("\n");
            failed = true;
        }

        if (failed)
        {
            print_usage(command_structure);
            Checks::exit_fail(VCPKG_LINE_INFO);
        }

        return output;
    }

    void print_usage()
    {
        HelpTableFormatter table;
        table.header("Commands");
        table.format("vcpkg search [pat]", "Search for packages available to be built");
        table.format("vcpkg install <pkg>...", "Install a package");
        table.format("vcpkg remove <pkg>...", "Uninstall a package");
        table.format("vcpkg remove --outdated", "Uninstall all out-of-date packages");
        table.format("vcpkg list", "List installed packages");
        table.format("vcpkg update", "Display list of packages for updating");
        table.format("vcpkg upgrade", "Rebuild all outdated packages");
        table.format("vcpkg x-history <pkg>", "(Experimental) Shows the history of CONTROL versions of a package");
        table.format("vcpkg hash <file> [alg]", "Hash a file by specific algorithm, default SHA512");
        table.format("vcpkg help topics", "Display the list of help topics");
        table.format("vcpkg help <topic>", "Display help for a specific topic");
        table.blank();
        Commands::Integrate::append_helpstring(table);
        table.blank();
        table.format("vcpkg export <pkg>... [opt]...", "Exports a package");
        table.format("vcpkg edit <pkg>",
                     "Open up a port for editing (uses " + format_environment_variable("EDITOR") + ", default 'code')");
        table.format("vcpkg import <pkg>", "Import a pre-built library");
        table.format("vcpkg create <pkg> <url> [archivename]", "Create a new package");
        table.format("vcpkg owns <pat>", "Search for files in installed packages");
        table.format("vcpkg depend-info <pkg>...", "Display a list of dependencies for packages");
        table.format("vcpkg env", "Creates a clean shell environment for development or compiling");
        table.format("vcpkg version", "Display version information");
        table.format("vcpkg contact", "Display contact information to send feedback");
        table.blank();
        table.header("Options");
        VcpkgCmdArguments::append_common_options(table);
        table.blank();
        table.format("@response_file", "Specify a response file to provide additional parameters");
        table.blank();
        table.example("For more help (including examples) see the accompanying README.md and docs folder.");
        System::print2(table.m_str);
    }

    void print_usage(const CommandStructure& command_structure)
    {
        HelpTableFormatter table;
        if (!command_structure.example_text.empty())
        {
            table.example(command_structure.example_text);
        }

        table.header("Options");
        for (auto&& option : command_structure.options.switches)
        {
            table.format(Strings::format("--%s", option.name), option.short_help_text);
        }
        for (auto&& option : command_structure.options.settings)
        {
            table.format(Strings::format("--%s=...", option.name), option.short_help_text);
        }
        for (auto&& option : command_structure.options.multisettings)
        {
            table.format(Strings::format("--%s=...", option.name), option.short_help_text);
        }

        VcpkgCmdArguments::append_common_options(table);
        System::print2(table.m_str);
    }

    void VcpkgCmdArguments::append_common_options(HelpTableFormatter& table)
    {
        static auto opt = [](StringView arg, StringView joiner, StringView value) {
            return Strings::format("--%s%s%s", arg, joiner, value);
        };

        table.format(opt(TRIPLET_ARG, " ", "<t>"), "Specify the target architecture triplet. See 'vcpkg help triplet'");
        table.format("", "(default: " + format_environment_variable("VCPKG_DEFAULT_TRIPLET") + ')');
        table.format(opt(OVERLAY_PORTS_ARG, "=", "<path>"), "Specify directories to be used when searching for ports");
        table.format(opt(OVERLAY_TRIPLETS_ARG, "=", "<path>"), "Specify directories containing triplets files");
        table.format(opt(BINARY_SOURCES_ARG, "=", "<path>"),
                     "Add sources for binary caching. See 'vcpkg help binarycaching'");
        table.format(opt(DOWNLOADS_ROOT_DIR_ARG, "=", "<path>"), "Specify the downloads root directory");
        table.format("", "(default: " + format_environment_variable("VCPKG_DOWNLOADS") + ')');
        table.format(opt(VCPKG_ROOT_DIR_ARG, " ", "<path>"), "Specify the vcpkg root directory");
        table.format("", "(default: " + format_environment_variable("VCPKG_ROOT") + ')');
        table.format(opt(BUILDTREES_ROOT_DIR_ARG, "=", "<path>"),
                     "(Experimental) Specify the buildtrees root directory");
        table.format(opt(INSTALL_ROOT_DIR_ARG, "=", "<path>"), "(Experimental) Specify the install root directory");
        table.format(opt(PACKAGES_ROOT_DIR_ARG, "=", "<path>"), "(Experimental) Specify the packages root directory");
        table.format(opt(SCRIPTS_ROOT_DIR_ARG, "=", "<path>"), "(Experimental) Specify the scripts root directory");
    }

    void VcpkgCmdArguments::imbue_from_environment()
    {
        if (!disable_metrics)
        {
            const auto vcpkg_disable_metrics_env = System::get_environment_variable(DISABLE_METRICS_ENV);
            if (vcpkg_disable_metrics_env.has_value())
            {
                disable_metrics = true;
            }
        }

        if (!triplet)
        {
            const auto vcpkg_default_triplet_env = System::get_environment_variable(TRIPLET_ENV);
            if (const auto unpacked = vcpkg_default_triplet_env.get())
            {
                triplet = std::make_unique<std::string>(*unpacked);
            }
        }

        if (!vcpkg_root_dir)
        {
            const auto vcpkg_root_env = System::get_environment_variable(VCPKG_ROOT_DIR_ENV);
            if (const auto unpacked = vcpkg_root_env.get())
            {
                vcpkg_root_dir = std::make_unique<std::string>(*unpacked);
            }
        }

        if (!downloads_root_dir)
        {
            const auto vcpkg_downloads_env = vcpkg::System::get_environment_variable(DOWNLOADS_ROOT_DIR_ENV);
            if (const auto unpacked = vcpkg_downloads_env.get())
            {
                downloads_root_dir = std::make_unique<std::string>(*unpacked);
            }
        }

        const auto vcpkg_feature_flags_env = System::get_environment_variable(FEATURE_FLAGS_ENV);
        if (const auto v = vcpkg_feature_flags_env.get())
        {
            auto flags = Strings::split(*v, ',');
            parse_feature_flags(flags, *this);
        }

        {
            const auto vcpkg_visual_studio_path_env = System::get_environment_variable(DEFAULT_VISUAL_STUDIO_PATH_ENV);
            if (const auto unpacked = vcpkg_visual_studio_path_env.get())
            {
                default_visual_studio_path = std::make_unique<std::string>(*unpacked);
            }
        }
    }

    void VcpkgCmdArguments::check_feature_flag_consistency() const
    {
        struct
        {
            StringView flag;
            StringView option;
            bool is_inconsistent;
        } possible_inconsistencies[] = {
            {BINARY_CACHING_FEATURE, BINARY_SOURCES_ARG, !binary_sources.empty() && !binary_caching.value_or(true)},
            {MANIFEST_MODE_FEATURE, MANIFEST_ROOT_DIR_ARG, manifest_root_dir && !manifest_mode.value_or(true)},
        };
        for (const auto& el : possible_inconsistencies)
        {
            if (el.is_inconsistent)
            {
                System::printf(System::Color::warning,
                               "Warning: %s feature specifically turned off, but --%s was specified.\n",
                               el.flag,
                               el.option);
                System::printf(System::Color::warning, "Warning: Defaulting to %s being on.\n", el.flag);
                Metrics::g_metrics.lock()->track_property(
                    "warning", Strings::format("warning %s alongside %s", el.flag, el.option));
            }
        }
    }

    void VcpkgCmdArguments::debug_print_feature_flags() const
    {
        struct
        {
            StringView name;
            Optional<bool> flag;
        } flags[] = {
            {BINARY_CACHING_FEATURE, binary_caching},
            {MANIFEST_MODE_FEATURE, manifest_mode},
            {COMPILER_TRACKING_FEATURE, compiler_tracking},
        };

        for (const auto& flag : flags)
        {
            if (auto r = flag.flag.get())
            {
                Debug::print("Feature flag '", flag.name, "' = ", *r ? "on" : "off", "\n");
            }
            else
            {
                Debug::print("Feature flag '", flag.name, "' unset\n");
            }
        }
    }

    void VcpkgCmdArguments::track_feature_flag_metrics() const
    {
        struct
        {
            StringView flag;
            bool enabled;
        } flags[] = {
            {BINARY_CACHING_FEATURE, binary_caching_enabled()},
            {COMPILER_TRACKING_FEATURE, compiler_tracking_enabled()},
        };

        for (const auto& flag : flags)
        {
            Metrics::g_metrics.lock()->track_feature(flag.flag.to_string(), flag.enabled);
        }
    }

    std::string format_environment_variable(StringLiteral lit)
    {
        std::string result;
#if defined(_WIN32)
        result.reserve(lit.size() + 2);
        result.push_back('%');
        result.append(lit.data(), lit.size());
        result.push_back('%');
#else
        result.reserve(lit.size() + 1);
        result.push_back('$');
        result.append(lit.data(), lit.size());
#endif
        return result;
    }

    std::string create_example_string(const std::string& command_and_arguments)
    {
        std::string cs = Strings::format("Example:\n"
                                         "  vcpkg %s\n",
                                         command_and_arguments);
        return cs;
    }

    static void help_table_newline_indent(std::string& target)
    {
        target.push_back('\n');
        target.append(34, ' ');
    }

    static constexpr ptrdiff_t S_MAX_LINE_LENGTH = 100;

    void HelpTableFormatter::format(StringView col1, StringView col2)
    {
        // 2 space, 31 col1, 1 space, 65 col2 = 99
        m_str.append(2, ' ');
        Strings::append(m_str, col1);
        if (col1.size() > 31)
        {
            help_table_newline_indent(m_str);
        }
        else
        {
            m_str.append(32 - col1.size(), ' ');
        }
        text(col2, 34);

        m_str.push_back('\n');
    }

    void HelpTableFormatter::header(StringView name)
    {
        m_str.append(name.data(), name.size());
        m_str.push_back(':');
        m_str.push_back('\n');
    }

    void HelpTableFormatter::example(StringView example_text)
    {
        m_str.append(example_text.data(), example_text.size());
        m_str.push_back('\n');
    }

    void HelpTableFormatter::blank() { m_str.push_back('\n'); }

    // Note: this formatting code does not properly handle unicode, however all of our documentation strings are English
    // ASCII.
    void HelpTableFormatter::text(StringView text, int indent)
    {
        const char* line_start = text.begin();
        const char* const e = text.end();
        const char* best_break = std::find_if(line_start, e, [](char ch) { return ch == ' ' || ch == '\n'; });

        while (best_break != e)
        {
            const char* next_break = std::find_if(best_break + 1, e, [](char ch) { return ch == ' ' || ch == '\n'; });
            if (*best_break == '\n' || next_break - line_start + indent > S_MAX_LINE_LENGTH)
            {
                m_str.append(line_start, best_break);
                m_str.push_back('\n');
                line_start = best_break + 1;
                best_break = next_break;
                m_str.append(indent, ' ');
            }
            else
            {
                best_break = next_break;
            }
        }
        m_str.append(line_start, best_break);
    }
}
