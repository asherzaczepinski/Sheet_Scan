<h1>Sheet Scan</h1>
<h3>The all-in-one practice companion for beginner musicians</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-lightgrey?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange?style=for-the-badge&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-blue?style=for-the-badge" alt="SwiftUI">
</p>

<h2>Overview</h2>
<p><strong>Sheet Scan</strong> combines the essential practice tools beginners need into one intuitive app. Instead of juggling separate tuner apps, random YouTube searches, paper scale sheets, and confusing metronomes, students get a single, clear place to learn the right way.</p>
<p><strong>What you can do:</strong> find instrument-specific recordings, see rhythm visually, tune accurately with real guidance, and learn scales faster with automatic fingerings and clear accidentals.</p>
<p><strong>Available now on the App Store.</strong></p>

<h2>Features</h2>

<h3>Smart Recording Finder</h3>
<p>Take a photo of your sheet music and get high-quality, instrument-specific recordings instantly.</p>
<ul>
  <li>Recognition: Google Vision API + Groq LLM</li>
  <li>Accuracy: scores by title, composer, and duration match</li>
  <li>Instrument filtering via YouTube Data API</li>
  <li>Saves time by avoiding low-quality or mislabeled videos</li>
</ul>

<h3>Visual Metronome</h3>
<p>Rhythm made visible for beginners.</p>
<ul>
  <li>Beat-by-beat visualization</li>
  <li>Subdivision display (eighths, triplets, sixteenths)</li>
  <li>Builds reliable timing for playing with others</li>
</ul>

<h3>Smart Tuner</h3>
<p>Not just pitch detection—coaching on how to fix it.</p>
<ul>
  <li>17 instruments supported (strings, brass, woodwinds)</li>
  <li>Real-time mic-based feedback with clear indicators</li>
  <li>Instrument-specific tips (e.g., clarinet: push/pull barrel)</li>
</ul>

<h3>Enhanced Scales</h3>
<p>Automatic fingerings and visual accidentals to speed up learning.</p>
<ul>
  <li>LilyPond + Python generate fingering diagrams</li>
  <li>Sharps/flats highlighted for clarity</li>
  <li>Multiple octaves and patterns</li>
</ul>

<h2>The Story Behind Sheet Scan</h2>
<p>I’ve played clarinet since 4th grade. Early on I bounced between cryptic tuners, metronomes without clear cues, and endless searches for decent recordings. I even spent time scribbling accidentals into scale books instead of improving sound and technique. <strong>Sheet Scan</strong> came from that frustration: a simple toolset that actually helps beginners practice correctly.</p>

<h2>Technology Stack</h2>
<table>
  <tr><th>Category</th><th>Technology</th></tr>
  <tr><td>Platform</td><td>iOS (Swift, SwiftUI)</td></tr>
  <tr><td>Computer Vision</td><td>Google Vision API</td></tr>
  <tr><td>AI / ML</td><td>Groq LLM</td></tr>
  <tr><td>Media</td><td>YouTube Data API</td></tr>
  <tr><td>Music Notation</td><td>LilyPond, Python</td></tr>
  <tr><td>Audio Processing</td><td>AVFoundation</td></tr>
</table>

<h2>Supported Instruments</h2>
<table>
  <tr>
    <td><strong>Woodwinds</strong></td>
    <td>Alto Saxophone, Tenor Saxophone, Clarinet, Bass Clarinet, Flute, Oboe, Bassoon</td>
  </tr>
  <tr>
    <td><strong>Brass</strong></td>
    <td>Trumpet, French Horn, Trombone, Euphonium, Tuba</td>
  </tr>
  <tr>
    <td><strong>Strings</strong></td>
    <td>Violin, Viola, Cello, Double Bass</td>
  </tr>
  <tr>
    <td><strong>Other</strong></td>
    <td>Piano</td>
  </tr>
</table>

<h2>How It Works</h2>
<ol>
  <li><strong>Scan Your Music</strong> — Take a photo showing the title and composer.</li>
  <li><strong>Get Recordings</strong> — Receive ranked, high-quality videos for your instrument.</li>
  <li><strong>Practice Smart</strong> — Use the visual metronome, tuner, and scales.</li>
  <li><strong>Track Progress</strong> — Your scan history keeps practice organized.</li>
</ol>

<h2>Installation</h2>
<p>Sheet Scan is available on the App Store for iOS devices.</p>

<h2>Requirements</h2>
<ul>
  <li>iOS 16.0 or later</li>
  <li>Camera access (for scanning)</li>
  <li>Microphone access (for tuner)</li>
  <li>Internet connection (for recording search)</li>
</ul>

<h2>Privacy &amp; Permissions</h2>
<table>
  <tr><th>Permission</th><th>Purpose</th></tr>
  <tr><td>Camera</td><td>Scan sheet music</td></tr>
  <tr><td>Photos</td><td>Select existing sheet music images</td></tr>
  <tr><td>Microphone</td><td>Pitch detection for tuner</td></tr>
  <tr><td>Internet</td><td>Search and fetch recordings</td></tr>
</table>
<p><small>Your privacy matters. Sheet music photos are processed securely and are not stored on external servers.</small></p>

<h2>Support</h2>
<p>Questions or feedback? Email: <a href="mailto:asherzac2020@gmail.com">asherzac2020@gmail.com</a></p>

<h2>License</h2>
<p>Copyright © 2025 Sheet Scan. All rights reserved.</p>

<p align="center"><strong>Made by a musician, for musicians</strong></p>
<p align="center"><small>Star this repo if Sheet Scan helped you practice better.</small></p>
