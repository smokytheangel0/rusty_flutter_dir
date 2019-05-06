import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
    group('database', () {
      final data_text = find.byValueKey('data_text');
      final result_text = find.byValueKey('result_text');
      final init_storage_button = find.byValueKey('init_storage_button');
      final store_one_button = find.byValueKey('store_one_button');
      final search_one_button = find.byValueKey('search_one_button');

      FlutterDriver driver;

      setUpAll(() async {
        driver = await FlutterDriver.connect();
      });

      tearDownAll(() async {
        if (driver != null) {
          driver.close();
        }
      });

      test('init_storage_test', () async {
        await driver.tap(init_storage_button);
        expect(await driver.getText(result_text), "Ok()");
      });

      test('store_one_test', () async {
        await driver.tap(store_one_button);
        expect(await driver.getText(result_text), "Ok()");
      });

      test('store_many_strings_test', () async {
      });

      test('store_many_different_test', () async {
      });

      test('search_one_test', () async {
        await driver.tap(search_one_button);
        expect(await driver.getText(result_text), "Ok()");
      });


      //this will use the write_data and read_data fns
      test('search_many_strings', () async {
      });

      test('search_many_different', () async {
      });

    });
    /*
    group('internet', () {
      //this will use an as yet unwritten get_data fn
      test('get_data', () {
        expect(false, true);
      });
    });

    group('counter', () {
      //this will test our int fn
      //this needs to be rearanged so it uses misc
      final result_finder = find.byValueKey('returned_value');
      final method_finder = find.byValueKey('method');
      final fields_finder = find.byValueKey('fields');
      final args_finder = find.byValueKey('args');
      final send_finder = find.byValueKey('send');

      FlutterDriver driver;

      setUpAll(() async {
        driver = await FlutterDriver.connect();
      });

      tearDownAll(() async {
        if (driver != null) {
          driver.close();
        }
      });

      test('increments the counter', () async {
        await driver.tap(method_finder);
        await driver.enterText("increment");

        await driver.tap(fields_finder);
        await driver.enterText("digit");

        await driver.tap(args_finder);
        await driver.enterText("0");

        await driver.tap(send_finder);

        expect(await driver.getText(result_finder), "1");
      });
    });

    group('hello', () {
      //this will test our encoding/decoding
      //this needs to be rearranged so that it uses misc
      final result_finder = find.byValueKey('returned_value');
      final method_finder = find.byValueKey('method');
      final fields_finder = find.byValueKey('fields');
      final args_finder = find.byValueKey('args');
      final send_finder = find.byValueKey('send');

      FlutterDriver driver;

      setUpAll(() async {
        driver = await FlutterDriver.connect();
      });

      tearDownAll(() async {
        if (driver != null) {
          driver.close();
        }
      });

      test('int_test', () async {
        await driver.tap(method_finder);
        await driver.enterText("hello");

        await driver.tap(fields_finder);
        await driver.enterText("name");

        await driver.tap(args_finder);
        await driver.enterText("0.toString()");

        await driver.tap(send_finder);

        expect(await driver.getText(result_finder), "hello 0!");
      });

      test('double_test', () async {
        await driver.tap(method_finder);
        await driver.enterText("hello");

        await driver.tap(fields_finder);
        await driver.enterText("name");

        await driver.tap(args_finder);
        await driver.enterText("0.0.toString()");

        await driver.tap(send_finder);

        expect(await driver.getText(result_finder), "hello 0.0!");
      });

      test('string_test', () async {
        await driver.tap(method_finder);
        await driver.enterText("hello");

        await driver.tap(fields_finder);
        await driver.enterText("name");

        await driver.tap(args_finder);
        await driver.enterText("bob");

        await driver.tap(send_finder);

        expect(await driver.getText(result_finder), "hello bob!");
      });

    });
    */
}