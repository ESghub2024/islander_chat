import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  //Instance of authentication
  final FirebaseAuth _fireBaseAuth = FirebaseAuth.instance;

  //Instance of firestore
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  //Sign user in
  Future<UserCredential> signInWithEmailandPassword(String email, String password) async{
    try{
      //Sign in
      UserCredential userCredential = 
      await _fireBaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password,
        );
        
         //Add a new document for a new user
        _fireStore.collection('users').doc(userCredential.user!.uid).set({
          'uid' : userCredential.user!.uid,
          'email' : email,
        }, SetOptions(merge: true));

        return userCredential;
    } 
    //Catch error
    on FirebaseAuthException catch (e){
      throw Exception(e.code);
    }

  }

  //Create a new user
  Future<UserCredential> signUpWithEmailandPassword(
    String email, String password, String nickname) async {
  try {
    UserCredential userCredential = await _fireBaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    _fireStore.collection('users').doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'email': email,
      'nickname': nickname, //Add nickname to Firestore
    });

    return userCredential;
  } on FirebaseAuthException catch (e) {
    throw Exception(e.code);
  }
}


  //Sign user out
  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }
}