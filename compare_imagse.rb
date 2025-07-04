require 'fileutils'
require 'json'

# Configuration
dir_a = './test_site/assets'  # Original images directory
dir_b = './test_site/_site/assets'  # Compressed images directory

output_html = "swipe_compare_#{Time.now.strftime('%Y%m%d_%H%M%S')}.html"
extensions = ['.jpg', '.jpeg', '.png', '.gif']

# Collect valid image pairs
image_pairs = []
Dir.glob("#{dir_a}/**/*").each do |file_a|
  next unless File.file?(file_a)
  next unless extensions.include?(File.extname(file_a).downcase)

  relative_path = file_a.sub(/^#{dir_a}\//, '')
  file_b = File.join(dir_b, relative_path)
  next unless File.exist?(file_b)

  size_a = File.size(file_a)
  size_b = File.size(file_b)

  image_pairs << {
    file_a: file_a,
    file_b: file_b,
    relative_path: relative_path,
    size_a: size_a,
    size_b: size_b
  }
end

# Start HTML
html = <<~HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Swipe Image Comparison</title>
  <style>
    body {
      font-family: sans-serif;
      text-align: center;
      padding: 20px;
      background: #f9f9f9;
      user-select: none;
      overflow-x: hidden;
      transition: background-color 0.3s ease;
    }
    .container {
      position: relative;
      width: 90vw;
      max-width: 900px;
      margin: 0 auto;
      height: 500px;
      overflow: visible;
    }
    .image-pair {
      position: absolute;
      top: 0; left: 50%;
      transform: translateX(-50%);
      width: 100%;
      display: flex;
      justify-content: center;
      gap: 4%;
      align-items: center;
      transition: transform 0.5s ease, opacity 0.5s ease;
      cursor: grab;
    }
    .image-pair img {
      max-width: 45%;
      border: 1px solid #ccc;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.15);
    }
    .file-info {
      margin-top: 10px;
      font-size: 14px;
    }
    .instructions {
      font-size: 18px;
      margin-bottom: 20px;
    }
    .done-message {
      display: none;
      font-size: 20px;
      margin-top: 30px;
    }
    /* Progress Bar */
    #progress-container {
      position: fixed;
      bottom: 0; left: 0; right: 0;
      height: 28px;
      background: #eee;
      box-shadow: inset 0 0 5px #ccc;
      display: flex;
      align-items: center;
      padding: 0 15px;
      font-size: 14px;
      color: #333;
      user-select: none;
    }
    #progress-bar {
      height: 8px;
      background: #4caf50;
      border-radius: 4px;
      width: 0%;
      transition: width 0.4s ease;
      margin-left: 10px;
      flex-grow: 1;
    }
  </style>
</head>
<body>
  <h1>Swipe Image Comparison</h1>
  <div class="instructions">
    Press <strong>Space</strong> or <strong>→</strong> to <span style="color:green;">Accept</span>,<br/>
    Press <strong>X</strong> or <strong>←</strong> to <span style="color:red;">Reject</span>
  </div>

  <div class="container" id="container">
    <div class="image-pair" id="imagePair">
      <img id="imgA" src="" alt="Original" />
      <img id="imgB" src="" alt="Compressed" />
    </div>
    <div class="file-info" id="info"></div>
  </div>

  <div class="done-message" id="doneMessage">
    All images reviewed. Downloading results...
  </div>

  <div id="progress-container">
    <div id="progress-text">0 / 0</div>
    <div id="progress-bar"></div>
  </div>

  <script>
    const imagePairs = [
HTML

image_pairs.each do |pair|
  html += "      #{{
    a: pair[:file_a],
    b: pair[:file_b],
    path: pair[:relative_path],
    sizeA: pair[:size_a],
    sizeB: pair[:size_b]
  }.to_json},\n"
end

html += <<~HTML
    ];

    let current = 0;
    const accepted = [];
    const rejected = [];

    const imgA = document.getElementById('imgA');
    const imgB = document.getElementById('imgB');
    const info = document.getElementById('info');
    const container = document.getElementById('container');
    const imagePair = document.getElementById('imagePair');
    const doneMessage = document.getElementById('doneMessage');
    const progressText = document.getElementById('progress-text');
    const progressBar = document.getElementById('progress-bar');
    const body = document.body;

    function updateProgress() {
      progressText.textContent = \`\${current} / \${imagePairs.length}\`;
      if(imagePairs.length > 0) {
        progressBar.style.width = ((current / imagePairs.length) * 100) + '%';
      } else {
        progressBar.style.width = '0%';
      }
    }

    function showPair(index) {
      if (index >= imagePairs.length) return;
      const pair = imagePairs[index];
      imgA.src = pair.a;
      imgB.src = pair.b;

      const percent = ((1 - pair.sizeB / pair.sizeA) * 100).toFixed(2);

      info.innerHTML = \`
        <div><strong>\${pair.path}</strong></div>
        <div>Original: \${pair.sizeA} bytes | Compressed: \${pair.sizeB} bytes</div>
        <div>Compression: \${percent}%</div>
      \`;

      // Reset transform & opacity
      imagePair.style.transition = 'none';
      imagePair.style.transform = 'translateX(-50%)';
      imagePair.style.opacity = '1';
      updateProgress();
    }

    function flashBackground(color) {
      body.style.backgroundColor = color;
      setTimeout(() => {
        body.style.backgroundColor = '#f9f9f9';
      }, 300);
    }

    function animateSwipe(direction, callback) {
      // direction: 'accept' = right, 'reject' = left
      imagePair.style.transition = 'transform 0.5s ease, opacity 0.5s ease';
      const offscreenX = direction === 'accept' ? '150vw' : '-150vw';
      imagePair.style.transform = \`translateX(\${offscreenX})\`;
      imagePair.style.opacity = '0';

      flashBackground(direction === 'accept' ? '#d4f8d4' : '#f8d4d4'); // Light green or red

      setTimeout(() => {
        callback();
      }, 500);
    }

    function handleChoice(type) {
      if (current >= imagePairs.length) return;

      const direction = (type === 'accepted') ? 'accept' : 'reject';

      animateSwipe(direction, () => {
        const pair = imagePairs[current];
        if (type === 'accepted') {
          accepted.push(pair.path);
        } else {
          rejected.push(pair.path);
        }

        current++;
        if (current >= imagePairs.length) {
          endSession();
        } else {
          showPair(current);
        }
      });
    }

    function endSession() {
      container.style.display = 'none';
      doneMessage.style.display = 'block';

      setTimeout(() => {
        saveCombinedResults(accepted, rejected);
      }, 500);
    }

    function saveCombinedResults(accepted, rejected) {
      let content = '';
      if (accepted.length > 0) {
        content += '--- Accepted Files ---\\n';
        content += accepted.join('\\n');
      }
      if (rejected.length > 0) {
        if (content.length > 0) content += '\\n\\n';
        content += '--- Rejected Files ---\\n';
        content += rejected.join('\\n');
      }

      const blob = new Blob([content], { type: 'text/plain' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'review_results.txt';
      a.click();
    }

    document.addEventListener('keydown', (e) => {
      if (e.code === 'Space' || e.code === 'ArrowRight') {
        e.preventDefault();
        handleChoice('accepted');
      } else if (e.key.toLowerCase() === 'x' || e.code === 'ArrowLeft') {
        handleChoice('rejected');
      }
    });

    if (imagePairs.length > 0) {
      showPair(0);
    } else {
      info.textContent = 'No image pairs found.';
      progressText.textContent = '0 / 0';
    }
  </script>
</body>
</html>
HTML

File.write(output_html, html)
puts "✅ Swipe-based HTML review generated: #{output_html}"
