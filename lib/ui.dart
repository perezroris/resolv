import 'package:flutter/material.dart';

import 'data.dart';

abstract final class InkColors {
  static const navy = Color(0xFF183753);
  static const ink = Color(0xFF152B40);
  static const muted = Color(0xFF50647A);
  static const blue = Color(0xFF285E93);
  static const pale = Color(0xFFE7F0F8);
  static const canvas = Color(0xFFF7F9FC);
  static const line = Color(0xFFD9E2EB);
  static const white = Colors.white;
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.person, {super.key, this.size = 42});
  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = person.avatar;
    final initials = Center(
      child: Text(
        person.initials,
        style: TextStyle(
          fontSize: size * .33,
          fontWeight: FontWeight.w700,
          color: InkColors.navy,
        ),
      ),
    );
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: InkColors.pale,
        ),
        child: photo == null
            ? initials
            : Image.asset(
                photo,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}

class BrandTag extends StatelessWidget {
  const BrandTag(this.text, {super.key, this.selected = false});
  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected ? InkColors.navy : InkColors.pale,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: selected ? InkColors.white : InkColors.blue,
        ),
      ),
    ),
  );
}
