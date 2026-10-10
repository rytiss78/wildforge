"""Lithuanian boss curses using edge-tts native Lithuanian voice."""
import asyncio
from pathlib import Path
import json, hashlib, struct, wave

root = Path(__file__).resolve().parents[1]
out = root / 'native/assets/voices'
lines = [
    'Po velnių!',
    'Kad tave perkūnas!',
    'Šūdas! Dar atsiimsi!',
    'Eik tu velniop!',
    'Aš jus visus sugniušku!',
    'Jūnų negalėsite pabėgti!',
    'Šiame pasaulyje nėra vietos baimingiesiems!',
    'Jėga manimi rūpinasi!',
    'Aš esu amžinas!',
    'Jūsų pasaulis man nepatinka!',
]


async def generate(text: str, tmp_mp3: Path) -> tuple[Path, int]:
    import edge_tts
    import subprocess
    comm = edge_tts.Communicate(text, 'lt-LT-LeonasNeural', rate='-15%', pitch='-20Hz')
    await comm.save(str(tmp_mp3))
    # Convert MP3 to WAV via ffmpeg
    wav_path = tmp_mp3.with_suffix('.wav')
    subprocess.run(
        ['C:/Users/rytis/AppData/Local/hermes/tools/ffmpeg-9.0.1-win32-x64/bin/ffmpeg.exe',
         '-i', str(tmp_mp3), '-f', 's16le', '-ar', '24000', '-ac', '1', '-y', str(wav_path)],
        capture_output=True, check=True
    )
    return wav_path, 24000


def apply_effects(pcm: bytes) -> bytes:
    samples = struct.unpack('<' + 'h' * (len(pcm) // 2), pcm)
    peak = max(abs(s) for s in samples) if samples else 1
    if peak > 0:
        scale = 0.82 * 32767.0 / peak
        samples = tuple(max(-32768, min(32767, int(s * scale))) for s in samples)
    fade_len = min(240, len(samples) // 10)
    fade_in = [i / fade_len for i in range(fade_len)]
    fade_out = [i / fade_len for i in range(fade_len, 0, -1)]
    samples = tuple(
        int(s * fade_in[i]) if i < fade_len else
        int(s * fade_out[i - len(samples)]) if i >= len(samples) - fade_len else s
        for i, s in enumerate(samples)
    )
    return struct.pack('<' + 'h' * len(samples), *samples)


def write_wav(path: Path, pcm: bytes, sr: int):
    with wave.open(str(path), 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm)


async def main():
    import tempfile
    records = []
    for i, text in enumerate(lines):
        with tempfile.TemporaryDirectory() as td:
            tmp_mp3 = Path(td) / f'boss_lt_{i}.mp3'
            wav_path, sr = await generate(text, tmp_mp3)
            # Apply effects to get final WAV
            with open(wav_path, 'rb') as f:
                pcm = f.read()
            pcm = apply_effects(pcm)
            final_path = out / f'boss_lt_{i}.wav'
            write_wav(final_path, pcm, sr)
            wav_path.unlink()
            records.append({
                'id': final_path.stem,
                'text': text,
                'language': 'lt',
                'duration': len(pcm) / 2 / sr,
                'sha256': hashlib.sha256(final_path.read_bytes()).hexdigest()
            })
            print(f'{text} {len(pcm)/2/sr:.2f}s')
    (out / 'boss-lithuanian-provenance.json').write_text(
        json.dumps({'engine': 'edge-tts lt-LT-LeonasNeural, native Lithuanian TTS', 'lines': records}, ensure_ascii=False, indent=2), encoding='utf-8'
    )


if __name__ == '__main__':
    asyncio.run(main())
