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
