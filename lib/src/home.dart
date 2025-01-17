import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rich_text_view/rich_text_view.dart';
import 'suggestion/cubit/suggestion_cubit.dart';
import 'suggestion/widget.dart';
import 'util.dart';

class RichTextView extends StatefulWidget {
  final String? text;
  final int? maxLines;
  final TextAlign? align;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextStyle? boldStyle;
  final bool showMoreText;
  final double? fontSize;
  final bool selectable;
  final bool editable;
  final bool autoFocus;
  final String? initialValue;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final Function(String)? onChanged;
  final int? maxLength;
  final int? minLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool readOnly;

  /// which position to append the suggested list defaults to [SuggestionPosition.bottom].
  final SuggestionPosition? suggestionPosition;

  final void Function(String)? onHashTagClicked;
  final void Function(String)? onMentionClicked;
  final void Function(String)? onEmailClicked;
  final void Function(String)? onUrlClicked;
  final void Function(String)? onBoldClicked;
  final Future<List<HashTag>> Function(String)? onSearchTags;
  final Future<List<Suggestion>> Function(String)? onSearchPeople;
  final List<ParsedType>? supportedTypes;

  /// initial suggested hashtags when the user enters `#`
  final List<HashTag>? hashtagSuggestions;

  /// initial suggested mentions when the user enters `@`
  final List<Suggestion>? mentionSuggestions;

  /// height of the suggestion item
  final double itemHeight;

  RichTextView(
      {this.text,
      this.maxLines,
      this.supportedTypes,
      this.align,
      this.style,
      this.linkStyle,
      this.boldStyle,
      this.showMoreText = true,
      this.selectable = true,
      this.controller,
      this.decoration,
      this.onChanged,
      this.editable = false,
      this.autoFocus = false,
      this.maxLength,
      this.minLines,
      this.keyboardType,
      this.focusNode,
      this.readOnly = false,
      this.initialValue,
      this.suggestionPosition = SuggestionPosition.bottom,
      this.fontSize,
      this.onHashTagClicked,
      this.onMentionClicked,
      this.onEmailClicked,
      this.onUrlClicked,
      this.onBoldClicked,
      this.onSearchTags,
      this.onSearchPeople,
      this.itemHeight = 80,
      this.hashtagSuggestions = const [],
      this.mentionSuggestions = const []});

  /// Creates a copy of [RichTextView] but with only the fields needed for
  /// the editor
  factory RichTextView.editor(
      {bool readOnly = false,
      bool autoFocus = false,
      String? initialValue,
      TextEditingController? controller,
      InputDecoration? decoration,
      Function(String)? onChanged,
      SuggestionPosition? suggestionPosition,
      int? maxLength,
      int? minLines,
      TextInputType? keyboardType,
      FocusNode? focusNode,
      List<HashTag>? hashtagSuggestions,
      List<Suggestion>? mentionSuggestions,
      Future<List<HashTag>> Function(String)? onSearchTags,
      Future<List<Suggestion>> Function(String)? onSearchPeople}) {
    return RichTextView(
      editable: true,
      onSearchPeople: onSearchPeople,
      onSearchTags: onSearchTags,
      readOnly: readOnly,
      suggestionPosition: suggestionPosition,
      autoFocus: autoFocus,
      initialValue: initialValue,
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      minLines: minLines,
      keyboardType: keyboardType,
      focusNode: focusNode,
      decoration: decoration,
      hashtagSuggestions: hashtagSuggestions,
      mentionSuggestions: mentionSuggestions,
    );
  }

  @override
  _RichTextViewState createState() => _RichTextViewState();
}

class _RichTextViewState extends State<RichTextView> {
  late int _maxLines;
  TextStyle? _style;
  bool flag = true;
  ValueNotifier<bool> expanded = ValueNotifier(false);
  late TextEditingController controller;
  late SuggestionCubit cubit;

  @override
  void initState() {
    super.initState();
    _maxLines = widget.maxLines ?? 2;
    controller = widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
    cubit = SuggestionCubit(widget.itemHeight);
  }

  Map<String, String?> formatBold({String? pattern, String? str}) {
    return {'display': str?.substring(1, str.length - 1)};
  }

  @override
  Widget build(BuildContext context) {
    _style = widget.style ??
        Theme.of(context)
            .textTheme
            .bodyText2!
            .copyWith(fontSize: widget.fontSize);

    var linkStyle = widget.linkStyle ??
        _style?.copyWith(color: Theme.of(context).accentColor);

    return !widget.editable
        ? Container(
            child: ParsedText(
                moreText: 'View more',
                text: widget.text!.trim(),
                linkStyle: linkStyle,
                onMore: () {
                  setState(() {
                    expanded.value = true;
                  });
                },
                expanded: expanded,
                selectable: widget.selectable,
                supportedTypes: widget.supportedTypes ??
                    const [
                      ParsedType.BOLD,
                      ParsedType.CUSTOM,
                      ParsedType.EMAIL,
                      ParsedType.MENTION,
                      ParsedType.PHONE,
                      ParsedType.URL,
                      ParsedType.HASH
                    ],
                parse: [
                  MatchText(
                    type: ParsedType.HASH,
                    style: linkStyle,
                    onTap: widget.onHashTagClicked,
                  ),
                  MatchText(
                    type: ParsedType.BOLD,
                    renderText: formatBold,
                    style: widget.boldStyle ??
                        widget.style?.copyWith(fontWeight: FontWeight.bold),
                    onTap: (txt) {
                      widget.onBoldClicked
                          ?.call(txt.substring(1, txt.length - 1));
                    },
                  ),
                  MatchText(
                    type: ParsedType.MENTION,
                    style: linkStyle,
                    onTap: widget.onMentionClicked,
                  ),
                  MatchText(
                    type: ParsedType.EMAIL,
                    style: linkStyle,
                    onTap: widget.onEmailClicked,
                  ),
                  MatchText(
                    type: ParsedType.URL,
                    style: linkStyle,
                    onTap: widget.onUrlClicked,
                  ),
                ],
                maxLines: _maxLines,
                style: _style))
        : Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.suggestionPosition == SuggestionPosition.top)
                  SuggestionWidget(
                    cubit: cubit,
                    controller: controller,
                    onTap: (contrl) {
                      setState(() {
                        controller = contrl;
                      });
                    },
                  ),
                BlocBuilder<SuggestionCubit, SuggestionState>(
                    bloc: cubit,
                    builder: (context, provider) {
                      return TextFormField(
                          style: widget.style,
                          focusNode: widget.focusNode,
                          controller: controller,
                          textCapitalization: TextCapitalization.sentences,
                          readOnly: widget.readOnly,
                          onChanged: (val) async {
                            widget.onChanged?.call(val);
                            cubit.onChanged(
                                val.split(' ').last.toLowerCase(),
                                widget.hashtagSuggestions,
                                widget.mentionSuggestions,
                                widget.onSearchTags,
                                widget.onSearchPeople);
                          },
                          maxLines: widget.maxLines,
                          keyboardType: widget.keyboardType,
                          maxLength: widget.maxLength,
                          minLines: widget.minLines,
                          autofocus: widget.autoFocus,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: widget.decoration);
                    }),
                if (widget.suggestionPosition == SuggestionPosition.bottom)
                  SuggestionWidget(
                    cubit: cubit,
                    controller: controller,
                    onTap: (contrl) {
                      setState(() {
                        controller = contrl;
                      });
                    },
                  ),
              ],
            ),
          );
  }
}
