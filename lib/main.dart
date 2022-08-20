import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'Your Publishable Key';
  //await Stripe.instance.applySettings();
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}

const primaryColor = Colors.blueAccent;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? paymentIntentData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment in Test Mode'),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: InkWell(
          onTap: () async {
            await openPaymentSheet();
          },
          child: Container(
            decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50))),
            height: 50,
            width: 200,
            child: const Center(
              child: Text(
                'Pay 20 Rupees',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPaymentSheet() async {
    try {
      paymentIntentData = await callPaymentIntentApi('20', 'INR');
      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
        appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
                colors: PaymentSheetPrimaryButtonTheme(
                    light: PaymentSheetPrimaryButtonThemeColors(
              background: Colors.orangeAccent,
            ))),
            colors: PaymentSheetAppearanceColors(background: primaryColor)),
        paymentIntentClientSecret: paymentIntentData!['client_secret'],
        style: ThemeMode.system,
        merchantDisplayName: 'Merchant Display Name',
      ))
          .then((value) {
        showPaymentSheet();
      });
    } catch (e, s) {
      print('Exception:$e$s');
    }
  }

  showPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((newValue) {
        //  print('Payment Intent Id'+paymentIntentData!['id'].toString());
        //  print('Payment Intent Client Secret'+paymentIntentData!['client_secret'].toString());
        //  print('Payment Intent Amount'+paymentIntentData!['amount'].toString());
        //  print('Payment Intent All Details'+paymentIntentData.toString());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text("👍 Paid Successfully Completed 😀")));
        paymentIntentData = null;
      }).onError((error, stackTrace) {
        print('Exception: $error $stackTrace');
      });
    } on StripeException catch (e) {
      print('StripeException:  $e');
      showDialog(
          context: context,
          builder: (_) => const AlertDialog(
                content: Text("Stripe Exception"),
              ));
    } catch (e) {
      print('$e');
    }
  }

  callPaymentIntentApi(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card'
      };
      print(body);
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer Your Secret Key',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      return jsonDecode(response.body);
    } catch (err) {
      print('callPaymentIntentApi Exception: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final a = (int.parse(amount)) * 100;
    return a.toString();
  }
  
}
