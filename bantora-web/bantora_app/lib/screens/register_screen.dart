import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/themed_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{1,14}$');

  static String _flagEmoji(String countryCode) {
    final upper = countryCode.trim().toUpperCase();
    if (upper.length != 2) {
      return '🏳️';
    }
    final a = upper.codeUnitAt(0);
    final b = upper.codeUnitAt(1);
    if (a < 65 || a > 90 || b < 65 || b > 90) {
      return '🏳️';
    }
    return String.fromCharCode(0x1F1E6 + (a - 65)) + String.fromCharCode(0x1F1E6 + (b - 65));
  }

  static Widget _flagBadge(String countryCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _flagEmoji(countryCode),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  void _onFormChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  final _phoneController = TextEditingController();
  final _preferredLanguageController = TextEditingController();
  final _preferredCurrencyController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _isCountriesLoading = false;
  String? _countriesLoadError;
  List<_RegistrationCountry> _countries = <_RegistrationCountry>[];

  _RegistrationCountry? _selectedCountry;
  _RegistrationCountry? _selectedCallingCountry;

  String? _selectedLanguageCode;
  String? _selectedCurrencyCode;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCountries();
    });
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onFormChanged);
    _passwordController.removeListener(_onFormChanged);
    _confirmPasswordController.removeListener(_onFormChanged);
    _phoneController.dispose();
    _preferredLanguageController.dispose();
    _preferredCurrencyController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _resolvePhoneNumberForApi() {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      return raw;
    }

    if (raw.startsWith('+')) {
      return raw;
    }

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final selected = _selectedCallingCountry ?? _selectedCountry;
    if (selected == null) {
      return digits;
    }
    final callingCodeDigits = selected.callingCode.replaceAll('+', '');
    return '+$callingCodeDigits$digits';
  }

  bool _canSubmit() {
    if (_isLoading) {
      return false;
    }

    if (_selectedCountry == null) {
      return false;
    }

    final resolvedPhone = _resolvePhoneNumberForApi();
    if (resolvedPhone.trim().isEmpty) {
      return false;
    }
    if (!_e164.hasMatch(resolvedPhone)) {
      return false;
    }

    final password = _passwordController.text;
    if (password.isEmpty || password.length < 8) {
      return false;
    }
    if (_confirmPasswordController.text != password) {
      return false;
    }

    final language = _selectedLanguageCode;
    if (language == null || language.trim().isEmpty) {
      return false;
    }

    final currency = _selectedCurrencyCode;
    if (currency == null || currency.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _loadCountries() async {
    if (_isCountriesLoading) return;

    setState(() {
      _isCountriesLoading = true;
      _countriesLoadError = null;
    });

    try {
      final apiService = Provider.of<AuthProvider>(context, listen: false).apiService;
      final raw = await apiService.getCountries();

      final parsed = raw.map(_RegistrationCountry.fromJson).toList();
      if (parsed.isEmpty) {
        throw StateError('No countries available');
      }
      parsed.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _countries = parsed;
        _selectedCountry = null;
        _selectedCallingCountry = null;
        _selectedCurrencyCode = null;
        _selectedLanguageCode = null;
        _preferredCurrencyController.text = '';
        _preferredLanguageController.text = '';
        _isCountriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _countriesLoadError = e.toString();
        _isCountriesLoading = false;
      });
    }
  }

  Future<void> _openCountryPicker() async {
    if (_isCountriesLoading) {
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (_isCountriesLoading && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (_countriesLoadError != null) {
      await _loadCountries();
      if (_countriesLoadError != null) {
        return;
      }
    }

    if (_countries.isEmpty) {
      await _loadCountries();
    }

    if (_countries.isEmpty) {
      return;
    }

    final selected = await showDialog<_RegistrationCountry>(
      context: context,
      builder: (context) {
        String query = '';

        return StatefulBuilder(
          builder: (context, setLocalState) {
            final q = query.trim().toLowerCase();
            final filtered = (q.isEmpty)
                ? _countries
                : _countries
                    .where((c) =>
                        c.code.toLowerCase().contains(q) ||
                        c.name.toLowerCase().contains(q) ||
                        c.callingCode.contains(q))
                    .toList();

            return AlertDialog(
              title: const Text('Select your nationality'),
              content: SizedBox(
                width: 360,
                height: 460,
                child: Column(
                  children: [
                    Semantics(
                      label: 'register_country_search_input',
                      textField: true,
                      child: TextField(
                        key: const Key('register_country_search_input'),
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setLocalState(() {
                            query = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching countries'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final country = filtered[index];
                                final label = 'register_country_option:${country.code}';
                                return Semantics(
                                  label: label,
                                  button: true,
                                  container: true,
                                  child: ExcludeSemantics(
                                    child: ListTile(
                                      key: Key(label),
                                      leading: _flagBadge(country.code),
                                      title: Text(country.name),
                                      subtitle: Text('${country.callingCode} • ${country.currency}'),
                                      trailing: Text(country.code),
                                      onTap: () => Navigator.of(context).pop(country),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      _selectedCountry = selected;
      _selectedCallingCountry = selected;
      _selectedCurrencyCode = selected.currency;
      _selectedLanguageCode = selected.defaultLanguage;

      _preferredCurrencyController.text = selected.currency;
      _preferredLanguageController.text = selected.defaultLanguageName ?? selected.defaultLanguage;
    });
  }

  Future<void> _openCallingCodePicker() async {
    if (_selectedCountry == null) {
      return;
    }

    final selected = await showDialog<_RegistrationCountry>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select country code'),
          content: SizedBox(
            width: 360,
            height: 460,
            child: ListView.builder(
              itemCount: _countries.length,
              itemBuilder: (context, index) {
                final country = _countries[index];
                final label = 'register_calling_code_option:${country.code}';
                return Semantics(
                  label: label,
                  button: true,
                  container: true,
                  child: ExcludeSemantics(
                    child: ListTile(
                      key: Key(label),
                      leading: _flagBadge(country.code),
                      title: Text(country.name),
                      subtitle: Text(country.callingCode),
                      trailing: Text(country.code),
                      onTap: () => Navigator.of(context).pop(country),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      _selectedCallingCountry = selected;
    });
  }

  Future<void> _openLanguagePicker() async {
    if (_selectedCountry == null) {
      return;
    }

    final byCode = <String, String>{};
    for (final country in _countries) {
      byCode.putIfAbsent(
        country.defaultLanguage,
        () => country.defaultLanguageName ?? country.defaultLanguage,
      );
    }
    final entries = byCode.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    final selected = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select language'),
          content: SizedBox(
            width: 360,
            height: 420,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final label = 'register_language_option:${entry.key}';
                return Semantics(
                  label: label,
                  button: true,
                  container: true,
                  child: ExcludeSemantics(
                    child: ListTile(
                      key: Key(label),
                      title: Text(entry.value),
                      onTap: () => Navigator.of(context).pop(entry),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      _selectedLanguageCode = selected.key;
      _preferredLanguageController.text = selected.value;
    });
  }

  Future<void> _openCurrencyPicker() async {
    if (_selectedCountry == null) {
      return;
    }

    final codes = _countries.map((c) => c.currency).toSet().toList()..sort();
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select currency'),
          content: SizedBox(
            width: 320,
            height: 360,
            child: ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final code = codes[index];
                final label = 'register_currency_option:$code';
                return Semantics(
                  label: label,
                  button: true,
                  container: true,
                  child: ExcludeSemantics(
                    child: ListTile(
                      key: Key(label),
                      title: Text(code),
                      onTap: () => Navigator.of(context).pop(code),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    setState(() {
      _selectedCurrencyCode = selected;
      _preferredCurrencyController.text = selected;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCountry = _selectedCountry;
    if (selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a nationality'), backgroundColor: Colors.red),
      );
      return;
    }

    final selectedLanguage = _selectedLanguageCode;
    if (selectedLanguage == null || selectedLanguage.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferred language is required'), backgroundColor: Colors.red),
      );
      return;
    }

    final selectedCurrency = _selectedCurrencyCode;
    if (selectedCurrency == null || selectedCurrency.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferred currency is required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.register(
      phoneNumber: _resolvePhoneNumberForApi(),
      password: _passwordController.text,
      countryCode: selectedCountry.code,
      preferredLanguage: selectedLanguage,
      preferredCurrency: selectedCurrency.trim().toUpperCase(),
      fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (_canSubmit()) {
                _register();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Register'),
            actions: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: ThemedLogo(width: 90, height: 90)),
                      const SizedBox(height: 16),

                      Semantics(
                        label: 'register_country_code_input',
                        button: true,
                        container: true,
                        onTap: _openCountryPicker,
                        excludeSemantics: true,
                        child: InkWell(
                          key: const Key('register_country_code_input'),
                          onTap: _openCountryPicker,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Nationality',
                              border: const OutlineInputBorder(),
                              prefixIcon: _isCountriesLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : (_selectedCountry == null
                                      ? const Icon(Icons.flag)
                                      : _flagBadge(_selectedCountry!.code)),
                            ),
                            child: Text(
                              _selectedCountry == null
                                  ? '--- Select Your Nationality ---'
                                  : _selectedCountry!.name,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedCountry != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'register_phone_input',
                          textField: true,
                          child: TextFormField(
                            key: const Key('register_phone_input'),
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone number',
                              border: const OutlineInputBorder(),
                              prefixIcon: InkWell(
                                onTap: _openCallingCodePicker,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _flagBadge(
                                        (_selectedCallingCountry?.code ?? _selectedCountry?.code ?? ''),
                                      ),
                                      const SizedBox(width: 8),
                                      Text((_selectedCallingCountry ?? _selectedCountry)!.callingCode),
                                    ],
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a phone number';
                              }
                              final resolved = _resolvePhoneNumberForApi();
                              if (!_e164.hasMatch(resolved)) {
                                return 'Phone number must be in international format (e.g. +263771234567)';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        Semantics(
                          label: 'register_preferred_language_input',
                          button: true,
                          container: true,
                          onTap: _openLanguagePicker,
                          excludeSemantics: true,
                          child: InkWell(
                            key: const Key('register_preferred_language_input'),
                            onTap: _openLanguagePicker,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Preferred language',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.language),
                              ),
                              child: Text(
                                _preferredLanguageController.text.trim().isEmpty
                                    ? '--- Select Language ---'
                                    : _preferredLanguageController.text,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Semantics(
                          label: 'register_preferred_currency_input',
                          button: true,
                          container: true,
                          onTap: _openCurrencyPicker,
                          excludeSemantics: true,
                          child: InkWell(
                            key: const Key('register_preferred_currency_input'),
                            onTap: _openCurrencyPicker,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Preferred currency',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payments),
                              ),
                              child: Text(
                                _preferredCurrencyController.text.trim().isEmpty
                                    ? '--- Select Currency ---'
                                    : _preferredCurrencyController.text,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'We recommend passwords with uppercase, lowercase, numbers and characters and minimum of 8 characters.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Semantics(
                          label: 'register_password_input',
                          textField: true,
                          child: TextFormField(
                            key: const Key('register_password_input'),
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'register_confirm_password_input',
                          textField: true,
                          child: TextFormField(
                            key: const Key('register_confirm_password_input'),
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (_canSubmit()) {
                                _register();
                              }
                            },
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Semantics(
                        label: 'register_button',
                        button: true,
                        enabled: _canSubmit(),
                        child: ElevatedButton(
                          key: const Key('register_button'),
                          onPressed: _canSubmit() ? _register : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Register'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Powered by T3raTech Solutions © 2025',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationCountry {
  final String code;
  final String name;
  final String callingCode;
  final String currency;
  final String defaultLanguage;
  final String? defaultLanguageName;

  const _RegistrationCountry({
    required this.code,
    required this.name,
    required this.callingCode,
    required this.currency,
    required this.defaultLanguage,
    required this.defaultLanguageName,
  });

  factory _RegistrationCountry.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String?)?.trim();
    final name = (json['name'] as String?)?.trim();
    final callingCode = (json['callingCode'] as String?)?.trim();
    final currency = (json['currency'] as String?)?.trim();
    final defaultLanguage = (json['defaultLanguage'] as String?)?.trim();
    final defaultLanguageName = (json['defaultLanguageName'] as String?)?.trim();

    if (code == null || code.isEmpty) {
      throw StateError('Invalid country: missing code');
    }
    if (name == null || name.isEmpty) {
      throw StateError('Invalid country: missing name');
    }
    if (callingCode == null || callingCode.isEmpty) {
      throw StateError('Invalid country: missing callingCode');
    }
    if (currency == null || currency.isEmpty) {
      throw StateError('Invalid country: missing currency');
    }
    if (defaultLanguage == null || defaultLanguage.isEmpty) {
      throw StateError('Invalid country: missing defaultLanguage');
    }

    return _RegistrationCountry(
      code: code.toUpperCase(),
      name: name,
      callingCode: callingCode,
      currency: currency.toUpperCase(),
      defaultLanguage: defaultLanguage,
      defaultLanguageName: defaultLanguageName,
    );
  }
}
