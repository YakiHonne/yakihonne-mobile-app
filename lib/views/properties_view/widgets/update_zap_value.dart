import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

class UpdateZapValue extends HookWidget {
  const UpdateZapValue({
    super.key,
    required this.index,
    required this.values,
  });

  final int index;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final valueTextController = useTextEditingController(
      text: values['value'],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ModalBottomSheetHandle(),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            'Update this custom zap',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          SvgPicture.asset(values['icon'].toString()),
          const SizedBox(
            height: kDefaultPadding,
          ),
          TextFormField(
            keyboardType: TextInputType.number,
            controller: valueTextController,
            decoration: InputDecoration(
              suffix: Text('SATS'),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          TextButton(
            onPressed: () {
              if (valueTextController.text.isNotEmpty &&
                  double.tryParse(valueTextController.text) != null) {
                context.read<LightningZapsCubit>().updateZap(
                  index: index,
                  value: {
                    'icon': values['icon'],
                    'value': valueTextController.text,
                  },
                );

                Navigator.pop(context);
              }
            },
            child: Text('update'),
          ),
          SizedBox(
            height:
                kDefaultPadding * 2 + MediaQuery.of(context).viewInsets.bottom,
          ),
        ],
      ),
    );
  }
}
