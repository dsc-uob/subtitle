## 0.2.0

### Performance
- **VTT and SRT parser rewritten** as a line-based cue-block parser. The file is split on blank lines and only the `-->` timing line is matched with a regex, eliminating the catastrophic backtracking that caused multi-second hangs on large karaoke-style VTT files. ([#21](https://github.com/dsc-uob/subtitle/issues/21))
- **`multiDurationSearch` is now O(log n + k)** — an upper-bound binary search locates the candidate window, then a backwards walk with a precomputed prefix-max-end array terminates as soon as no further active cue is possible.
- **Cue deduplication** runs automatically after parsing and sorting. Same-range cues are collapsed to the longest text; contiguous cues with identical text and a gap ≤ 50 ms are merged into one. This keeps karaoke-style files manageable without losing visible content.

### Fixes
- VTT cue identifiers (named cues such as `intro` or `chapter-1`) are now parsed correctly — cue names no longer bleed into `.data`. ([#20](https://github.com/dsc-uob/subtitle/issues/20))
- VTT positioning directives (`line:`, `position:`, `align:`, etc.) on the timing line are silently skipped; only the cue text that follows is extracted.
- Network and file fetching now attempt strict UTF-8 decoding first and fall back to Latin-1 for subtitle files served in legacy encodings. ([#10](https://github.com/dsc-uob/subtitle/issues/10))

### API additions
- `Subtitle.copyWith({index, data, start, end})` — creates a modified copy of a subtitle cue.

## 0.1.4
- Fix: Resolved issues related to new line handling in subtitle parsers.
- Test: Added comprehensive tests for all subtitle formats. (#18)
- Fix: Corrected regex handling for ttml_subtitle to ensure proper parsing.
- Improvement: Adjusted parsers to maintain \n consistency, aligning with VTT and SRT styles as intended by subtitle authors.

## 0.1.3
- Solved issue with StringSubtitle, see #16 for more.
- Added dispose for SubtitleController, see #11 for more.
- Solved issues #9 and #4 in #12, thanks for (@fadone).

## 0.1.0
- Addressed an issue with subtitle parsing (srt) that was affecting certain cases. This contribution is credited to @sahanForaty. Refer to issue #6.
- Resolved a network subtitle problem, contributed by @thecarry98. See issue #8.
- Corrected the issue associated with the unclosed HttpClient in the network subtitle handling.
- Added SRT format example.

## 0.1.0-beta.3
- Fix srt bug.
- Remove path package from dependency.
- Rewrite and enhance regular expressions.

## 0.1.0-beta.2
- Add `SubtitleController` and its feature like: 
    - Binary search for single search by providing the duration.
    - Multi result search by providing the duration.
- Re-architect the files of project.
- Update regex of `VttRegex` and `SrtRegex`.
- Fix `SubtitleParser` bug when decoding the subtitles.
- You can normalize the subtitle text data while decoding, like remove css styles.
- Manual provide of the `SubtitleType`, or leave it to detected auto.
- Fix `dart:io` bug to support dart js and flutter web by using `universal_io` package.
- Reducing non-required dependency `http` package.
- 3 examples added.

## 0.1.0-beta.1

- **SubtitleProvider:** Simplifies fetching subtitle file data from multiple sources.
- **SubtitleRepository:** Deals with the platform directly to get or download the required data and submit it to the provider.
- **SubtitleParser:** Used to analyze and convert subtitle files into software objects that are viewable and usable.
- **CustomSubtitleParser:** Customizable subtitle parser, for custom regexes.
- **SubtitleRegexObject:** Responsible for providing the necessary expression for the purpose of decoding the content of subtitle files, has 4 children:
    - **VttRegex:** WebVTT regexp.
    - **SrtRegex:** SubRip regexp.
    - **TtmlRegex:** TTML or DFXP regex
    - **CustomRegex:** User define regexp.
- **SubtitleObject:** Store the subtitle file data and its format type.
- Initial version, created by [MuhmdHsn313](https://twitter.com/MuhmdHsn313)
