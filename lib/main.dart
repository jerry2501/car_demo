import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';

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
  bool _isme=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Demo'),
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
              SizedBox(height: 10,),
              RaisedButton(
                color: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Text('Register your Name',style: TextStyle(color: Colors.white),),
                onPressed: (_isme)?null :(){
                  SetData();
                },
              ),
              SizedBox(height: 20,),
              if(_isme) Text('Congratulations!! You are Owner of the Car!!',style: TextStyle(color: Colors.indigo,fontSize: 18,fontWeight: FontWeight.bold,)),
            ],
          ),
        ),
      ),
    );
  }

  Future SetData() async{
    await Firebase.initializeApp();
    DocumentReference documentReference = FirebaseFirestore.instance
  .collection('cars')
  .doc('ferrari');

return Firestore.instance.runTransaction((transaction) async {
  // Get the document
  DocumentSnapshot snapshot = await transaction.get(documentReference);

  if (!snapshot.exists) {
    throw Exception("User does not exist!");
  }

  // Perform an update on the document
  if(snapshot.data()['has_owner']==false){
    transaction.update(documentReference, {'has_owner': true,'owner_name':name});
    setState(() {
      _isme=true;
    });
  }
  else{
    print('Car already has an owner!!');
    Toast.show("Car already has an Owner!!", context, duration: Toast.LENGTH_LONG, gravity:  Toast.CENTER);
  }
  

  return true;
})
.catchError((error) => print("Failed to update: $error"));
  }
}