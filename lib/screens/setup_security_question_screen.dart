// imports for flutter widgets and secure storage
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:coocue/screens/parent_home_screen.dart';

// screen where user sets up a security question and answer
class SetupSecurityQuestionScreen extends StatefulWidget {
  const SetupSecurityQuestionScreen({super.key});

  @override
  State<SetupSecurityQuestionScreen> createState() =>
      _SetupSecurityQuestionScreenState();
}

class _SetupSecurityQuestionScreenState
    extends State<SetupSecurityQuestionScreen> {
  // list of questions shown in dropdown
  final List<String> questions = [
    'What’s your favorite color?',
    'Name of the nurse who discharged your child?',
    'What middle name were you going to give your baby?',
    'What is the name of your child’s favorite toy?',
  ];

  // secure storage to save question and answer
  final _storage = FlutterSecureStorage();

  // current selected question
  String? selectedQuestion;
  // controller for answer text field
  final TextEditingController answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // app logo at top
                Image.asset('assets/images/coocue_logo2.png', height: 40),
                const SizedBox(height: 30),
                // heading text
                const Text(
                  'Security Setup',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF3F51B5),
                  ),
                ),
                const SizedBox(height: 25),
                // description text
                const Text(
                  'Choose a security question and answer to reset your PIN in the future.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF656565),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 60),
                // dropdown to pick a question
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  focusColor: Colors.white,
                  iconEnabledColor: const Color(0xFF3F51B5),
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF3F51B5)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    hoverColor: Colors.white,
                    iconColor: Color(0xff3F51B5),
                  ),
                  hint: const Text(
                    'Select a Security Question',
                    style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
                  ),
                  value: selectedQuestion,
                  items: questions
                      .map(
                        (q) => DropdownMenuItem(
                          value: q,
                          child: Text(
                            q,
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedQuestion = val),
                ),
                const SizedBox(height: 25),
                // text field to enter the answer
                TextField(
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16),
                  controller: answerController,
                  decoration: InputDecoration(
                    hintText: 'Your Answer',
                    filled: true,
                    hintStyle: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16,
                      color: Color(0xff656565),
                    ),
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffd9d9d9)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // submit button to save and navigate
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      // keys for storage
                      final questionKey = 'sec_question';
                      final answerKey = 'sec_answer';

                      // normalize answer for case-insensitive comparison
                      final normalizedAnswer =
                          answerController.text.trim().toLowerCase();

                      // write question and answer to secure storage
                      await _storage.write(
                        key: questionKey,
                        value: selectedQuestion,
                      );
                      await _storage.write(
                        key: answerKey,
                        value: normalizedAnswer,
                      );

                      // go to parent home screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentHomeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'LeagueSpartan',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
