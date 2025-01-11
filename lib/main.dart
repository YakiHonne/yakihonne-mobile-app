import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/blocs/app_clients_cubit/app_clients_cubit.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/notes_events_cubit/notes_events_cubit.dart';
import 'package:yakihonne/blocs/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/blocs/relays_progress_cubit/relays_progress_cubit.dart';
import 'package:yakihonne/blocs/routing_cubit/routing_cubit.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/routes/app_router.dart';
import 'package:yakihonne/utils/global_keys.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/relay_progress_bar.dart';

late LocalDatabaseRepository localDatabaseRepository;

late NostrDataRepository nostrRepository;

late AuthorsCubit authorsCubit;

late AppClientsCubit appClientsCubit;

late PointsManagementCubit pointsManagementCubit;

late ThemeCubit themeCubit;

late SingleEventCubit singleEventCubit;

late NotesEventsCubit notesEventsCubit;

late NotificationsCubit notificationsCubit;

late DmsCubit dmsCubit;

late LightningZapsCubit lightningZapsCubit;

late RelaysProgressCubit relaysProgressCubit;

final uuid = Uuid();

void main() async {
  await iniApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final botToastBuilder = BotToastInit();

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => ConnectivityRepository(),
          ),
          RepositoryProvider(
            create: (co5ntext) => localDatabaseRepository,
          ),
          RepositoryProvider(
            create: (context) => nostrRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => themeCubit),
            BlocProvider(create: (context) => pointsManagementCubit),
            BlocProvider(
              create: (context) => RoutingCubit(
                connectivityRepository: context.read<ConnectivityRepository>(),
                nostrRepository: context.read<NostrDataRepository>(),
                localDatabaseRepository:
                    context.read<LocalDatabaseRepository>(),
              )..routingViewInit(context),
            ),
            BlocProvider(
              create: (context) => lightningZapsCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => authorsCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => appClientsCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => notificationsCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => singleEventCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => notesEventsCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => dmsCubit,
              lazy: false,
            ),
            BlocProvider(
              create: (context) => relaysProgressCubit,
              lazy: false,
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  if (relaysProgressCubit.state.isRelaysVisible) {
                    relaysProgressCubit.setRelaysListVisibility(false);
                  } else {
                    context.read<RelaysProgressCubit>().dismissProgressBar();
                  }
                },
                child: Portal(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: state.theme == AppTheme.purpleWhite
                        ? AppThemes.appLightTheme
                        : AppThemes.appDarkTheme,
                    onGenerateRoute: (settings) => onGenerateRoute(settings),
                    navigatorObservers: [
                      FirebaseAnalyticsObserver(
                        analytics: FirebaseAnalytics.instance,
                      ),
                      BotToastNavigatorObserver(),
                    ],
                    navigatorKey: GlobalKeys.navigatorKey,
                    builder: EasyLoading.init(
                      builder: (context, child) {
                        child = botToastBuilder(context, child);

                        return Stack(
                          children: [
                            MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                textScaler: TextScaler.linear(
                                  state.textScaleFactor,
                                ),
                              ),
                              child: ResponsiveBreakpoints.builder(
                                child: child,
                                breakpoints: [
                                  const Breakpoint(
                                    start: 0,
                                    end: 450,
                                    name: MOBILE,
                                  ),
                                  const Breakpoint(
                                    start: 451,
                                    end: 800,
                                    name: TABLET,
                                  ),
                                  const Breakpoint(
                                    start: 801,
                                    end: 1920,
                                    name: DESKTOP,
                                  ),
                                  const Breakpoint(
                                    start: 1921,
                                    end: double.infinity,
                                    name: '4K',
                                  ),
                                ],
                              ),
                            ),
                            RelaysProgressBar(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
