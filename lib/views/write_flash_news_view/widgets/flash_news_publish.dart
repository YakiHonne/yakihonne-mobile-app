import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/write_flash_news_cubit/write_flash_news_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/constants.dart';

class FlashNewsPublish extends StatelessWidget {
  const FlashNewsPublish({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(kDefaultPadding),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (nostrRepository.flashNewsPrice +
                        (state.isImportant
                            ? nostrRepository.importantTagPrice
                            : 0))
                    .toInt()
                    .toString(),
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'SATS',
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kOrange,
                    ),
              ),
              if (state.isImportant) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Text(
                  'Flash news importance: +${nostrRepository.importantTagPrice} SATS',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(fontWeight: FontWeight.w800, color: kDimGrey),
                ),
              ],
              const SizedBox(
                height: kDefaultPadding,
              ),
              BlocConsumer<LightningZapsCubit, LightningZapsState>(
                listener: (context, state) {
                  if (state.confirmPayment) {
                    BotToastUtils.showWarning(
                      'Your flash news is stored locally for further use',
                    );
                  }
                },
                builder: (context, state) {
                  if (state.confirmPayment) {
                    return TextButton(
                      onPressed: () {
                        context.read<WriteFlashNewsCubit>().submitEvent(
                          () {
                            Navigator.pop(context);
                          },
                        );
                      },
                      child: Text(
                        'Confirm payment',
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.labelMedium,
                    children: [
                      TextSpan(
                        text: 'Note: ',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kRed,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      TextSpan(
                        text:
                            'Ensure that all the content that you provided is final since the publishing is deemed irreversible & the spent SATS are ',
                      ),
                      TextSpan(
                        text: 'non refundable.',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
