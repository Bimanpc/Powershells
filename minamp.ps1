<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>AI Winamp-style Media Player</title>
<style>
  :root{
    --bg:#2c2c2c;
    --panel:#1f1f1f;
    --accent:#00ff6a; /* Winamp-ish neon green */
    --accent2:#00b3ff; /* cyan */
    --text:#e8e8e8;
    --muted:#9aa0a6;
    --btn:#3a3a3a;
    --btn-hover:#4a4a4a;
    --danger:#ff4d4f;
    --good:#39ff14;
  }
  *{box-sizing:border-box;user-select:none}
  html,body{height:100%;background:var(--bg);color:var(--text);font-family:Verdana, Geneva, Tahoma, sans-serif}
  body{margin:0;display:flex;align-items:center;justify-content:center;padding:12px}
  .winamp{
    width: 860px;
    background: linear-gradient(#262626,#1a1a1a);
    border: 1px solid #000;
    box-shadow: 0 10px 30px rgba(0,0,0,0.6), inset 0 2px 0 rgba(255,255,255,0.06);
    position:relative;
  }
  .titlebar{
    height:32px; display:flex; align-items:center; justify-content:space-between;
    background: linear-gradient(#303030,#1f1f1f);
    border-bottom: 1px solid #000; padding:0 8px;
  }
  .titlebar .appname{letter-spacing:1px; font-weight:bold; color:var(--accent)}
  .titlebar .buttons{display:flex; gap:6px}
  .chip{
    padding:4px 8px; background:var(--btn); border:1px solid #111; color:var(--accent2);
    font-size:12px; text-transform:uppercase; cursor:pointer;
  }
  .chip:hover{background:var(--btn-hover)}
  .main{
    display:grid; grid-template-columns: 520px 1fr; grid-template-rows: auto auto 180px; gap:0; min-height: 520px;
  }
  .display{
    grid-column:1 / 3; background: var(--panel);
    border-bottom:1px solid #000; display:flex; align-items:center; gap:14px; padding:12px;
  }
  .screen{
    flex:1; height:100px; background:#101010; border:1px solid #000; position:relative;
    display:flex; align-items:center; justify-content:center; overflow:hidden;
  }
  .lcd{
    font-family: "Courier New", monospace; font-weight:bold; font-size: 22px;
    color: var(--accent); text-shadow: 0 0 6px #00ff6a77;
  }
  .meter{
    width:200px; height:100px; background:#111; border:1px solid #000; position:relative; overflow:hidden;
  }
  .meter canvas{width:100%; height:100%}
  .controls{
    grid-column:1; background: var(--panel); border-right:1px solid #000; padding:10px;
  }
  .btnbar{display:flex; gap:8px; flex-wrap:wrap}
  .btn{
    background: linear-gradient(#3a3a3a,#2a2a2a); border:1px solid #000; color:#eaeaea;
    width:70px; height:28px; display:flex; align-items:center; justify-content:center;
    font-size:12px; cursor:pointer;
  }
  .btn:hover{filter:brightness(1.15)}
  .transport{margin-top:10px; display:flex; gap:8px; flex-wrap:wrap}
  .transport .btn{width:52px}
  .seek{
    margin-top:10px; display:flex; align-items:center; gap:8px;
  }
  input[type="range"]{width:300px}
  .slider-label{font-size:12px; color:var(--muted)}
  .eq{
    margin-top:10px; padding:8px; border:1px solid #000; background:#181818;
    display:grid; grid-template-columns: repeat(6, 1fr); gap:6px;
  }
  .eq .band{display:flex; flex-direction:column; align-items:center; gap:4px}
  .eq .band label{font-size:11px; color:var(--muted)}
  .playlist{
    grid-column:2; background:var(--panel); padding:10px; display:flex; flex-direction:column; gap:8px;
  }
  .playlist-header{display:flex; justify-content:space-between; align-items:center}
  .playlist-list{
    border:1px solid #000; background:#141414; min-height:230px; max-height:230px; overflow:auto; padding:6px;
  }
  .track{
    padding:6px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid #0a0a0a; cursor:pointer;
  }
  .track:hover{background:#1c1c1c}
  .track .name{color:#dcdcdc}
  .track .dur{color:var(--muted); font-size:12px}
  .ai{
    grid-column:1 / 3; background: var(--panel); padding:10px; border-top:1px solid #000; display:grid; grid-template-columns: 2fr 1fr; gap:10px;
  }
  .ai .prompt, .ai .notes{
    border:1px solid #000; background:#141414; padding:8px;
  }
  textarea{width:100%; height:90px; background:#0f0f0f; color:#ddd; border:1px solid #000; resize:vertical; padding:6px}
  .small{font-size:12px; color:var(--muted)}
  .status{margin-top:4px; font-size:12px}
  .good{color:var(--good)} .bad{color:var(--danger)}
  .hidden{display:none !important}
  .file-input{display:none}
  .kbd{border:1px solid #000; background:#0c0c0c; padding:4px 6px; color:#bbb; font-size:12px}
</style>
</head>
<body>
<div class="winamp" role="application" aria-label="AI LLM Winamp-style Media Player">
  <div class="titlebar">
    <div class="appname">AI LLM MEDIA PLAYER — WINAMP STYLE</div>
    <div class="buttons">
      <label class="chip" for="filePicker">Open</label>
      <button class="chip" id="savePlaylistBtn">Save list</button>
      <button class="chip" id="loadPlaylistBtn">Load list</button>
      <button class="chip" id="clearBtn">Clear</button>
    </div>
    <input id="filePicker" class="file-input" type="file" accept="audio/*,video/*" multiple />
  </div>

  <div class="main">
    <div class="display">
      <div class="screen"><div class="lcd" id="lcd">00:00 / 00:00 — Ready</div></div>
      <div class="meter"><canvas id="viz"></canvas></div>
    </div>

    <div class="controls">
      <div class="btnbar">
        <button class="btn" id="addUrlBtn">Add URL</button>
        <button class="btn" id="shuffleBtn">Shuffle</button>
        <button class="btn" id="repeatBtn">Repeat: Off</button>
        <button class="btn" id="stopBtn">Stop</button>
      </div>

      <div class="transport">
        <button class="btn" id="prevBtn">Prev</button>
        <button class="btn" id="playBtn">Play</button>
        <button class="btn" id="pauseBtn">Pause</button>
        <button class="btn" id="nextBtn">Next</button>
      </div>

      <div class="seek">
        <span class="slider-label">Position</span>
        <input id="seek" type="range" min="0" max="1000" step="1" value="0" />
        <span class="slider-label" id="rateLbl">Rate 1.0x</span>
        <input id="rate" type="range" min="0.5" max="2.0" step="0.05" value="1.0" />
      </div>

      <div class="eq" aria-label="Equalizer">
        <div class="band">
          <label>Gain</label>
          <input type="range" id="gain" min="-20" max="20" step="1" value="0" />
        </div>
        <div class="band">
          <label>Bass</label>
          <input type="range" data-f="90" class="biquad" min="-30" max="30" step="1" value="0" />
        </div>
        <div class="band">
          <label>Low-mid</label>
          <input type="range" data-f="250" class="biquad" min="-30" max="30" step="1" value="0" />
        </div>
        <div class="band">
          <label>Mid</label>
          <input type="range" data-f="1000" class="biquad" min="-30" max="30" step="1" value="0" />
        </div>
        <div class="band">
          <label>High-mid</label>
          <input type="range" data-f="3000" class="biquad" min="-30" max="30" step="1" value="0" />
        </div>
        <div class="band">
          <label>Treble</label>
          <input type="range" data-f="8000" class="biquad" min="-30" max="30" step="1" value="0" />
        </div>
      </div>
    </div>

    <div class="playlist">
      <div class="playlist-header">
        <div>
          <span class="kbd">Tip: Drag & drop files here</span>
        </div>
        <div class="small">Supported: MP3, WAV, OGG, AAC, MP4, WebM (browser-dependent)</div>
      </div>
      <div id="playlist" class="playlist-list" tabindex="0" aria-label="Playlist"></div>
    </div>

    <div class="ai">
      <div class="prompt">
        <div class="small">AI DJ / LLM</div>
        <textarea id="prompt" placeholder="Ask the AI: 'Summarize lyrics', 'Suggest next tracks', 'Generate a playlist by mood', 'What’s the genre?'"></textarea>
        <div class="btnbar">
          <button class="btn" id="askBtn">Ask AI</button>
          <button class="btn" id="tagBtn">Auto-tags</button>
          <button class="btn" id="transcribeBtn">Transcribe</button>
        </div>
        <div id="aiStatus" class="status"></div>
        <div id="aiOut" class="notes" style="margin-top:8px; min-height:80px"></div>
      </div>
      <div class="notes">
        <div class="small">Now playing metadata</div>
        <div id="meta">
          <div><b>Title:</b> <span id="metaTitle">—</span></div>
          <div><b>Source:</b> <span id="metaSrc">—</span></div>
          <div><b>Type:</b> <span id="metaType">—</span></div>
          <div><b>Duration:</b> <span id="metaDur">—</span></div>
          <div><b>Tags:</b> <span id="metaTags">—</span></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Hidden media element -->
  <audio id="player" crossorigin="anonymous"></audio>
  <video id="vplayer" class="hidden" crossorigin="anonymous"></video>
</div>

<script>
(() => {
  const player = document.getElementById('player');
  const vplayer = document.getElementById('vplayer');
  const isVideoType = (type) => type?.startsWith('video/');

  let currentIndex = -1;
  let playlist = [];
  let repeat = false;
  let shuffle = false;

  // Web Audio setup
  const actx = new (window.AudioContext || window.webkitAudioContext)();
  const source = actx.createMediaElementSource(player);
  const gainNode = actx.createGain();
  const analyser = actx.createAnalyser();
  analyser.fftSize = 1024;
  const biquads = [90,250,1000,3000,8000].map(f=>{
    const b = actx.createBiquadFilter();
    b.type='peaking'; b.frequency.value=f; b.Q.value=1.0; b.gain.value=0;
    return b;
  });
  // chain: source -> biquads -> gain -> analyser -> destination
  source.connect(biquads[0]);
  for(let i=0;i<biquads.length-1;i++) biquads[i].connect(biquads[i+1]);
  biquads.at(-1).connect(gainNode);
  gainNode.connect(analyser);
  analyser.connect(actx.destination);

  // Visualization
  const viz = document.getElementById('viz');
  const vctx = viz.getContext('2d');
  const buffer = new Uint8Array(analyser.frequencyBinCount);
  function drawViz(){
    requestAnimationFrame(drawViz);
    analyser.getByteFrequencyData(buffer);
    const w = viz.width = viz.clientWidth;
    const h = viz.height = viz.clientHeight;
    vctx.clearRect(0,0,w,h);
    const barW = Math.max(2, w / buffer.length);
    for(let i=0;i<buffer.length;i++){
      const val = buffer[i];
      const barH = (val/255) * h;
      const x = i*barW;
      vctx.fillStyle = `hsl(${120-(val/255)*120}, 100%, 50%)`;
      vctx.fillRect(x, h-barH, barW-1, barH);
    }
  }
  drawViz();

  // UI elements
  const lcd = document.getElementById('lcd');
  const seek = document.getElementById('seek');
  const rate = document.getElementById('rate');
  const rateLbl = document.getElementById('rateLbl');
  const gain = document.getElementById('gain');
  const playlistDiv = document.getElementById('playlist');
  const metaTitle = document.getElementById('metaTitle');
  const metaSrc = document.getElementById('metaSrc');
  const metaType = document.getElementById('metaType');
  const metaDur = document.getElementById('metaDur');
  const metaTags = document.getElementById('metaTags');

  // Buttons
  const playBtn = document.getElementById('playBtn');
  const pauseBtn = document.getElementById('pauseBtn');
  const stopBtn = document.getElementById('stopBtn');
  const prevBtn = document.getElementById('prevBtn');
  const nextBtn = document.getElementById('nextBtn');
  const shuffleBtn = document.getElementById('shuffleBtn');
  const repeatBtn = document.getElementById('repeatBtn');
  const addUrlBtn = document.getElementById('addUrlBtn');
  const filePicker = document.getElementById('filePicker');
  const savePlaylistBtn = document.getElementById('savePlaylistBtn');
  const loadPlaylistBtn = document.getElementById('loadPlaylistBtn');
  const clearBtn = document.getElementById('clearBtn');

  // AI elements
  const askBtn = document.getElementById('askBtn');
  const tagBtn = document.getElementById('tagBtn');
  const transcribeBtn = document.getElementById('transcribeBtn');
  const aiOut = document.getElementById('aiOut');
  const aiStatus = document.getElementById('aiStatus');
  const promptEl = document.getElementById('prompt');

  // Helpers
  function fmt(t){
    if(!isFinite(t)||t<0) return '00:00';
    const m = Math.floor(t/60).toString().padStart(2,'0');
    const s = Math.floor(t%60).toString().padStart(2,'0');
    return `${m}:${s}`;
  }
  function updateLCD(){
    const dur = player.duration || vplayer.duration || 0;
    const cur = player.currentTime || vplayer.currentTime || 0;
    const name = playlist[currentIndex]?.name ?? '—';
    lcd.textContent = `${fmt(cur)} / ${fmt(dur)} — ${name}`;
  }
  function setMeta(item){
    if(!item){ metaTitle.textContent='—'; metaSrc.textContent='—'; metaType.textContent='—'; metaDur.textContent='—'; return; }
    metaTitle.textContent = item.name;
    metaSrc.textContent = item.src;
    metaType.textContent = item.type || 'unknown';
    metaDur.textContent = '…';
  }
  function rebuildPlaylist(){
    playlistDiv.innerHTML = '';
    playlist.forEach((it, idx)=>{
      const el = document.createElement('div'); el.className='track';
      el.innerHTML = `<div class="name">${it.name}</div><div class="dur">${it.dur?fmt(it.dur):''}</div>`;
      el.addEventListener('click', ()=>loadIndex(idx,true));
      playlistDiv.appendChild(el);
    });
  }
  function addFiles(files){
    for(const f of files){
      const url = URL.createObjectURL(f);
      playlist.push({name: f.name, src: url, type: f.type});
    }
    rebuildPlaylist();
    if(currentIndex===-1 && playlist.length>0) loadIndex(0,false);
  }
  function addUrl(){
    const src = prompt('Enter media URL (audio/video):');
    if(!src) return;
    const name = src.split('/').pop() || 'Stream';
    const type = src.endsWith('.mp4')||src.endsWith('.webm')?'video/*':'audio/*';
    playlist.push({name, src, type});
    rebuildPlaylist();
    if(currentIndex===-1) loadIndex(playlist.length-1,false);
  }
  function decideElement(type){
    const useVideo = isVideoType(type);
    player.classList.toggle('hidden', useVideo);
    vplayer.classList.toggle('hidden', !useVideo);
    return useVideo? vplayer: player;
  }
  function loadIndex(idx, autoplay){
    currentIndex = idx;
    const item = playlist[idx];
    if(!item) return;
    const el = decideElement(item.type);
    el.src = item.src;
    el.load?.();
    setMeta(item);
    metaDur.textContent = '…';
    // when metadata loads, duration is available
    el.onloadedmetadata = ()=>{
      item.dur = el.duration;
      metaDur.textContent = fmt(el.duration);
      rebuildPlaylist();
    };
    if(autoplay){ el.play?.(); actx.resume(); }
  }
  function play(){ (player.classList.contains('hidden')? vplayer : player).play(); actx.resume(); }
  function pause(){ (player.classList.contains('hidden')? vplayer : player).pause(); }
  function stop(){
    const el = player.classList.contains('hidden')? vplayer : player;
    el.pause(); el.currentTime = 0; updateLCD();
  }
  function next(){
    if(playlist.length===0) return;
    if(shuffle){
      const candidates = [...Array(playlist.length).keys()].filter(i=>i!==currentIndex);
      const pick = candidates[Math.floor(Math.random()*candidates.length)];
      loadIndex(pick,true); return;
    }
    let idx = currentIndex+1;
    if(idx>=playlist.length){ idx = 0; }
    loadIndex(idx,true);
  }
  function prev(){
    if(playlist.length===0) return;
    let idx = currentIndex-1;
    if(idx<0){ idx = playlist.length-1; }
    loadIndex(idx,true);
  }

  // Events
  filePicker.addEventListener('change', e=> addFiles(e.target.files));
  playlistDiv.addEventListener('dragover', e=>{ e.preventDefault(); });
  playlistDiv.addEventListener('drop', e=>{
    e.preventDefault();
    const files = e.dataTransfer.files;
    if(files?.length) addFiles(files);
  });
  addUrlBtn.addEventListener('click', addUrl);
  playBtn.addEventListener('click', play);
  pauseBtn.addEventListener('click', pause);
  stopBtn.addEventListener('click', stop);
  nextBtn.addEventListener('click', next);
  prevBtn.addEventListener('click', prev);
  shuffleBtn.addEventListener('click', ()=>{
    shuffle = !shuffle;
    shuffleBtn.textContent = shuffle? 'Shuffle: On' : 'Shuffle';
  });
  repeatBtn.addEventListener('click', ()=>{
    repeat = !repeat;
    repeatBtn.textContent = repeat? 'Repeat: On' : 'Repeat: Off';
  });

  // Seek & rate
  setInterval(updateLCD, 250);
  [player, vplayer].forEach(el=>{
    el.addEventListener('timeupdate', ()=>{
      const dur = el.duration || 1;
      seek.value = Math.floor((el.currentTime/dur)*1000);
      updateLCD();
    });
    el.addEventListener('ended', ()=>{
      if(repeat) { el.currentTime=0; el.play(); return; }
      next();
    });
  });
  seek.addEventListener('input', ()=>{
    const el = player.classList.contains('hidden')? vplayer : player;
    const dur = el.duration || 1;
    el.currentTime = (seek.value/1000)*dur;
    updateLCD();
  });
  rate.addEventListener('input', ()=>{
    const el = player.classList.contains('hidden')? vplayer : player;
    el.playbackRate = parseFloat(rate.value);
    rateLbl.textContent = `Rate ${el.playbackRate.toFixed(2)}x`;
  });

  // EQ & Gain
  gain.addEventListener('input', ()=>{
    const db = parseFloat(gain.value);
    // convert dB to linear
    gainNode.gain.value = Math.pow(10, db/20);
  });
  document.querySelectorAll('.biquad').forEach((sld, i)=>{
    sld.addEventListener('input', ()=>{
      biquads[i].gain.value = parseFloat(sld.value);
    });
  });

  // Save / Load playlist (JSON)
  savePlaylistBtn.addEventListener('click', ()=>{
    const json = JSON.stringify(playlist.map(p=>({name:p.name, src:p.src, type:p.type, dur:p.dur||null})), null, 2);
    const blob = new Blob([json], {type:'application/json'});
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = 'playlist.json'; a.click();
    URL.revokeObjectURL(a.href);
  });
  loadPlaylistBtn.addEventListener('click', async ()=>{
    const input = document.createElement('input');
    input.type='file'; input.accept='application/json';
    input.onchange = async ()=>{
      const f = input.files[0]; if(!f) return;
      const text = await f.text();
      try{
        const arr = JSON.parse(text);
        playlist = arr;
        rebuildPlaylist();
        if(arr.length>0) loadIndex(0,false);
      }catch(e){ alert('Invalid playlist file'); }
    };
    input.click();
  });
  clearBtn.addEventListener('click', ()=>{
    stop();
    playlist = [];
    currentIndex = -1;
    rebuildPlaylist();
    setMeta(null);
    lcd.textContent = '00:00 / 00:00 — Ready';
  });

  // AI stub wiring
  async function callLLM(task, payload){
    aiStatus.textContent = 'Thinking…';
    try{
      // Replace with your backend endpoint
      const res = await fetch('/api/llm', {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({task, payload})
      });
      if(!res.ok) throw new Error('LLM error');
      const data = await res.json();
      aiStatus.textContent = '';
      return data.output || JSON.stringify(data);
    }catch(err){
      aiStatus.innerHTML = `<span class="bad">AI error: ${err.message}</span>`;
      return '';
    }
  }
  askBtn.addEventListener('click', async ()=>{
    const q = promptEl.value.trim();
    if(!q){ aiStatus.innerHTML = '<span class="bad">Enter a prompt.</span>'; return; }
    const now = playlist[currentIndex] || null;
    const output = await callLLM('chat', {
      question: q,
      nowPlaying: now ? {title: now.name, src: now.src, type: now.type, duration: now.dur||null} : null,
      library: playlist.map(p=>({title:p.name, type:p.type, duration:p.dur||null}))
    });
    aiOut.textContent = output || '';
  });
  tagBtn.addEventListener('click', async ()=>{
    const now = playlist[currentIndex];
    if(!now){ aiStatus.innerHTML = '<span class="bad">No track selected.</span>'; return; }
    const output = await callLLM('tags', {title: now.name});
    metaTags.textContent = output || '—';
  });
  transcribeBtn.addEventListener('click', async ()=>{
    const now = playlist[currentIndex];
    if(!now){ aiStatus.innerHTML = '<span class="bad">No track selected.</span>'; return; }
    // For local files (blob URLs) you’d stream the file to backend for STT
    const output = await callLLM('transcribe', {src: now.src, title: now.name});
    aiOut.textContent = output || '';
  });

  // Keyboard shortcuts
  document.addEventListener('keydown', (e)=>{
    if(e.code==='Space'){ e.preventDefault(); const el = player.classList.contains('hidden')? vplayer : player; el.paused? play(): pause(); }
    if(e.code==='ArrowRight'){ const el = player.classList.contains('hidden')? vplayer : player; el.currentTime += 5; }
    if(e.code==='ArrowLeft'){ const el = player.classList.contains('hidden')? vplayer : player; el.currentTime -= 5; }
    if(e.code==='KeyN'){ next(); }
    if(e.code==='KeyP'){ prev(); }
  });

  // Initial hint
  lcd.textContent = '00:00 / 00:00 — Ready';
})();
</script>
</body>
</html>
