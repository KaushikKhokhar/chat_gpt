// ignore_for_file: avoid_print

import 'dart:async';

import 'package:chat_gpt/chat_message.dart';
import 'package:chat_gpt/three_dots.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Chat extends StatefulWidget {
  Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();

  List<ChatMessage> _message = [];
  ChatGPT? chatGPT;
  StreamSubscription? _subscription;
  bool buttonEnable = true;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    chatGPT = ChatGPT.instance;
    _controller.addListener(() {
      final buttonEnable = _controller.text.isEmpty;
      setState(() {
        this.buttonEnable = buttonEnable;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  void sendMessage() {
    setState(() {
      buttonEnable = true;
      ChatMessage message = ChatMessage(text: _controller.text, sender: 'User');
      setState(() {
        _message.insert(0, message);
        isTyping = true;
      });
      _controller.clear();

      final request = CompleteReq(
          prompt: message.text, model: kTranslateModelV3, max_tokens: 200);
      _subscription = chatGPT!
          .builder(
            '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',
          )
          .onCompleteStream(request: request)
          .listen((response) {
        print(response!.choices[0].text);
        ChatMessage botMessage =
            ChatMessage(text: response.choices[0].text, sender: 'Bot');
        setState(() {
          isTyping = false;
          _message.insert(0, botMessage);
        });
      });
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.send,
            onSubmitted: (value) {
              sendMessage();
              FocusScope.of(context).nextFocus();
            },
            controller: _controller,
            decoration: InputDecoration(
              fillColor: Theme.of(context).cardColor,
              filled: true,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none),
              hintText: 'Send a message',
              contentPadding:
                  const EdgeInsets.only(top: 13, bottom: 13, left: 19),
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          // TextField(
          //   textInputAction: TextInputAction.send,
          //   onSubmitted: (value) {
          //     sendMessage();
          //     FocusScope.of(context).nextFocus();
          //   },
          //   controller: _controller,
          //   decoration: const InputDecoration(
          //     hintText: 'Send a message',
          //   ),
          // ),
        ),
        const SizedBox(
          width: 4,
        ),
        InkWell(
          onTap: buttonEnable ? null : sendMessage,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: Icon(
              color: buttonEnable ? Colors.black38 : Colors.black,
              (Icons.send),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'ChatGPT',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Flexible(
            child: ListView.builder(
                reverse: true,
                itemCount: _message.length,
                itemBuilder: (context, index) {
                  return _message[index];
                }),
          ),
          Opacity(opacity: 0.5),
          if (isTyping) const ThreeDots(),
          Container(
            child: _buildTextComposer(),
          ),
        ]),
      ),
    );
  }
}
