import 'package:bloc/bloc.dart';
import 'package:reorderable_list/theme/darkmode_event.dart';
import 'package:reorderable_list/theme/darkmode_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeBloc extends Bloc<DarkModeEvent, DarkModeState> {
  late SharedPreferences prefs;

  DarkModeBloc() : super(const DarkModeState(isDarkMode: false)) {
    on<LoadDarkMode>(_onLoadDarkMode);
    on<ToggleDarkMode>(_onToggleDarkMode);
    _initialize();
  }

  Future<void> _initialize() async {
    prefs = await SharedPreferences.getInstance();
    var darkMode = prefs.getBool("darkMode") ?? false;
    add(LoadDarkMode(darkMode));
  }

  void _onLoadDarkMode(LoadDarkMode event, Emitter<DarkModeState> emit) {
    emit(DarkModeState(isDarkMode: event.darkMode));
  }

  void _onToggleDarkMode(ToggleDarkMode event, Emitter<DarkModeState> emit) {
    final newState = !state.isDarkMode;
    emit(DarkModeState(isDarkMode: newState));
    prefs.setBool("darkMode", newState);
  }
}
