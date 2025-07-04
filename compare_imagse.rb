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
    body { font-family: sans-serif; text-align: center; padding: 20px; background: #f9f9f9; }
    img { max-width: 45%; margin: 0 2%; border: 1px solid #ccc; }
    .image-container { margin: 40px 0; }
    .instructions { font-size: 18px; margin-bottom: 20px; }
    .file-info { margin-top: 10px; font-size: 14px; }
    .done-message { display: none; font-size: 20px; margin-top: 30px; }
  </style>
</head>
<body>
  <h1>Swipe Image Comparison</h1>
  <div class="instructions">
    Press <strong>Space</strong> or <strong>→</strong> to <span style="color:green;">Accept</span>,
    <strong>X</strong> or <strong>←</strong> to <span style="color:red;">Reject</span>
  </div>

  <div id="viewer">
    <div class="image-container">
      <img id="imgA" src="" alt="Original" />
      <img id="imgB" src="" alt="Compressed" />
    </div>
    <div class="file-info" id="info"></div>
  </div>

  <div class="done-message" id="doneMessage">
    All images reviewed. Downloading results...
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
    const viewer = document.getElementById('viewer');
    const doneMessage = document.getElementById('doneMessage');

    function showPair(index) {
      const pair = imagePairs[index];
      imgA.src = pair.a;
      imgB.src = pair.b;

      const percent = ((1 - pair.sizeB / pair.sizeA) * 100).toFixed(2);

      info.innerHTML = `
        <div><strong>\${pair.path}</strong></div>
        <div>Original: \${pair.sizeA} bytes | Compressed: \${pair.sizeB} bytes</div>
        <div>Compression: \${percent}%</div>
      `;
    }

    function handleChoice(type) {
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
    }

    function endSession() {
      viewer.style.display = 'none';
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
        handleChoice('accepted');
        e.preventDefault();
      } else if (e.key.toLowerCase() === 'x' || e.code === 'ArrowLeft') {
        handleChoice('rejected');
      }
    });

    if (imagePairs.length > 0) {
      showPair(0);
    } else {
      info.textContent = 'No image pairs found.';
    }
  </script>
</body>
</html>
HTML

# Write output file
File.write(output_html, html)
puts "✅ Swipe-based HTML review generated: #{output_html}"
