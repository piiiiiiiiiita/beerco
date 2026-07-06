# beerco

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Jak spustit Android emulator bez chyb debuggu

Nejlepší workaround je spouštět bez DDS:
cd /Users/mai/Documents/App/beerco
flutter run -d emulator-5554 --no-dds
A když už appka běží a chceš se připojit ručně:
flutter attach -d emulator-5554 --no-dds

Spouštět appku pro testování bez řešení CLI debug session:
cd /Users/mai/Documents/App/beerco
flutter install -d emulator-5554
