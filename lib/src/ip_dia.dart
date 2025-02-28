import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IpDialog extends StatelessWidget {
  final TextEditingController urlCltr;
  final bool isRealDevice;
  const IpDialog({Key? key, required this.urlCltr, this.isRealDevice = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        const Center(
          child: Text(
            "IP Address",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        TextField(
          controller: urlCltr,
          readOnly: isRealDevice,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            hintText: '192.168.x.xx',
            suffixIcon: isRealDevice
                ? IconButton(
                    icon: const Icon(Icons.copy, color: Colors.black54),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: urlCltr.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        // Center(
        //   child: Container(
        //     decoration: BoxDecoration(
        //         borderRadius: BorderRadius.circular(5),
        //         border: Border.all(color: Colors.black26)),
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        //     child: SelectableText(
        //       urlCltr.text,
        //       style: const TextStyle(
        //         fontSize: 16,
        //       ),
        //     ),
        //   ),
        // ),
        const SizedBox(
          height: 24,
        ),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(isRealDevice ? "Close" : "Submit")),
      ],
    );
  }
}
