// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/models/wallet_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';

class CustomDropDownWithDefault extends StatelessWidget {
  const CustomDropDownWithDefault({
    super.key,
    required this.list,
    required this.initialValue,
    required this.defaultValue,
    this.onChanged,
    this.formKey,
    this.isDisabled,
    this.validator,
  });

  final List<String> list;
  final Function(String?)? onChanged;
  final String initialValue;
  final String defaultValue;
  final GlobalKey<FormFieldState>? formKey;
  final bool? isDisabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      key: formKey,
      validator: validator,
      value: defaultValue,
      isExpanded: true,
      borderRadius: BorderRadius.circular(5),
      menuMaxHeight: 50.h,
      dropdownColor: Theme.of(context).primaryColorLight.withAlpha(235),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(
            initialValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kDimGrey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...list
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e.split('wss://')[1],
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList()
      ],
      onChanged: isDisabled == null ? onChanged : null,
    );
  }
}

class CustomDropDown extends StatelessWidget {
  const CustomDropDown({
    super.key,
    required this.list,
    this.onChanged,
    this.formKey,
    this.isDisabled,
    this.validator,
    required this.defaultValue,
  });

  final List<String> list;
  final Function(String?)? onChanged;
  final String defaultValue;
  final GlobalKey<FormFieldState>? formKey;
  final bool? isDisabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      key: formKey,
      validator: validator,
      value: defaultValue,
      isExpanded: true,
      borderRadius: BorderRadius.circular(5),
      menuMaxHeight: 50.h,
      dropdownColor: Theme.of(context).primaryColorLight.withAlpha(235),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
      ),
      items: list
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: TextStyle(
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isDisabled == null ? onChanged : null,
    );
  }
}

class WalletsCustomDropDown extends HookWidget {
  const WalletsCustomDropDown({
    Key? key,
    required this.list,
    required this.defaultValue,
    required this.formKey,
    required this.onDelete,
    required this.onChanged,
  }) : super(key: key);

  final List<WalletModel> list;
  final String defaultValue;
  final GlobalKey<FormFieldState> formKey;
  final Function(String) onDelete;
  final Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final isMenuOpen = useState(false);

    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        key: formKey,
        value: defaultValue,
        isExpanded: true,
        buttonStyleData: ButtonStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).primaryColorLight,
          ),
          padding: const EdgeInsets.only(right: kDefaultPadding / 2),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).primaryColorLight,
          ),
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
          ),
        ),
        onMenuStateChange: (isOpen) async {
          isMenuOpen.value = isOpen;
        },
        items: list
            .map(
              (e) => DropdownMenuItem(
                value: e.id,
                child: StatefulBuilder(
                  builder: (context, menuSetState) => Row(
                    children: [
                      if (defaultValue == e.id) ...[
                        DotContainer(
                          color: kGreen,
                          isNotMarging: true,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                      ],
                      Expanded(
                        child: Text(
                          e.lud16,
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: defaultValue == e.id ? kGreen : null,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMenuOpen.value)
                        IconButton(
                          onPressed: () {
                            if (isMenuOpen.value) {
                              onDelete.call(e.id);
                            }
                          },
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                          icon: Icon(
                            Icons.remove,
                            color: kRed,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class CustomDropDownWithMap extends StatelessWidget {
  const CustomDropDownWithMap({
    super.key,
    required this.list,
    this.onChanged,
    this.formKey,
    this.isDisabled,
    this.validator,
    required this.initialValue,
    required this.defaultValue,
  });

  final Map<String, String> list;
  final Function(String?)? onChanged;
  final String initialValue;
  final String defaultValue;
  final GlobalKey<FormFieldState>? formKey;
  final bool? isDisabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      key: formKey,
      validator: validator,
      value: defaultValue,
      isExpanded: true,
      dropdownColor: kWhite,
      borderRadius: BorderRadius.circular(5),
      menuMaxHeight: 50.h,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
      ),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(
            initialValue,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: kDimGrey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...list.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList()
      ],
      onChanged: isDisabled == null ? onChanged : null,
    );
  }
}

class RelaysCustomDropDown extends StatelessWidget {
  const RelaysCustomDropDown({
    super.key,
    required this.list,
    this.onChanged,
    this.formKey,
    required this.defaultValue,
  });

  final List<String> list;
  final Function(String?)? onChanged;
  final String defaultValue;
  final GlobalKey<FormFieldState>? formKey;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      key: formKey,
      value: defaultValue,
      isExpanded: true,
      dropdownColor: Theme.of(context).primaryColorLight.withAlpha(235),
      borderRadius: BorderRadius.circular(5),
      menuMaxHeight: 50.h,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: list
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e.split('wss://')[1],
                style: TextStyle(
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
