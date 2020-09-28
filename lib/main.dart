import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitUp
  ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String name;
  double amount;
  QuerySnapshot snapshot;
  bool _isme=false;
  Razorpay razor;   

   void openCheckout() async
  {
    var cred = 'rzp_test_VkSC53IBttT7cf:2qSCAty9bFHehpRUlECI2pNE';
    var bytes = utf8.encode(cred);
    var base64str = base64.encode(bytes);
    var response = await http.post(
      'https://api.razorpay.com/v1/orders',
      headers: {
        'content-type':'application/json',
        'authorization':'Basic $base64str'
        },
      body: json.encode({
        'amount':amount*100,
        'currency':'INR',
      })
    );
    final res=json.decode(response.body);
    print(res['id']);
    var options={
      'key':'rzp_test_VkSC53IBttT7cf',
      'amount':amount*100,
      'name':'Jignesh',
      'order_id':res['id'],
      'external':{
        'wallets':['paytm']
      }
    };

    try{
      razor.open(options);
    }
    catch(e){
      debugPrint(e);
    }
  }

  void handlerPaymentSuccess(PaymentSuccessResponse response)
  {
    Toast.show('Success'+response.paymentId, context);
    updateData();
  }

  void handlerPaymentError(PaymentFailureResponse response)
  {
    Toast.show('Error'+response.code.toString()+' . '+response.message, context);
  }

  void handlerPaymentExternal(ExternalWalletResponse response)
  {
    Toast.show('External Wallet'+response.walletName, context);
    updateData();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    razor=Razorpay();
    razor.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlerPaymentSuccess);
    razor.on(Razorpay.EVENT_PAYMENT_ERROR, handlerPaymentError);
    razor.on(Razorpay.EVENT_EXTERNAL_WALLET, handlerPaymentExternal);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    razor.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Razorpay Demo'),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(left: 8,right: 8,bottom: 8),
                child: TextField(
                  autocorrect: true,
                  decoration: InputDecoration(
                    suffixIcon: GestureDetector(
                      child: Icon(Icons.search,),
                      onTap: (){
                        //Write code to get user snapshot
                        if(name==null){
                          Toast.show('Enter some Name!!', context,gravity: Toast.CENTER);
                          return;
                        }
                        getUserData(name);
                      },
                      ),
                    labelText: 'Name',
                    focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
            ),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
            ),
                    hintText: 'Enter your Name'
                  ),
                  onChanged: (value){
                    setState(() {
                      name=value;
                    });
                  },
                ),
              ),
              SizedBox(height:10),
              if(_isme) Container(
                padding: EdgeInsets.only(left: 8,right: 8,bottom: 8),
                child: TextField(
                  autocorrect: true,
                  keyboardType: TextInputType.numberWithOptions(
                  signed: false
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
            ),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
            ),
                    hintText: 'Enter the Amount'
                  ),
                  onChanged: (value){
                    setState(() {
                      amount=double.parse(value);
                    });
                  },
                ),
              ),
              SizedBox(height: 10,),
              RaisedButton(
                color: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Text('Pay',style: TextStyle(color: Colors.white),),
                onPressed: (!_isme)?null :(){
                  if(amount>snapshot.documents[0].data()['pending_amount']  || amount==null){
                    Toast.show('Please Enter Correct amount!!', context,gravity: Toast.CENTER);
                    return;}
                  openCheckout();
                },
              ),
              SizedBox(height: 20,),
              if(_isme) Text('${snapshot.documents[0].data()['pending_amount']}  Rupees is Pending to Pay',style: TextStyle(color: Colors.indigo,fontSize: 18,fontWeight: FontWeight.bold,)),
            ],
          ),
        ),
      ),
    );
  }

  Future getUserData(String name) async{
    await Firebase.initializeApp();
     snapshot = await Firestore.instance.collection('users').where('name',isEqualTo: name.trim().toUpperCase()).get();
     setState(() {
       _isme=true;
     });
  }

  Future updateData() async{
    await Firebase.initializeApp();
    await Firestore.instance.collection('users').document(snapshot.documents[0].documentID).update({
      'pending_amount': snapshot.documents[0].data()['pending_amount']-amount,
    });
    snapshot = await Firestore.instance.collection('users').where('name',isEqualTo: name.trim().toUpperCase()).get();
    setState(() {
      
    });
  }
}