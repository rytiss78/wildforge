"""Lithuanian boss curses using edge-tts native Lithuanian voice."""
import asyncio
from pathlib import Path
import json, hashlib

root = Path(__file__).resolve().parents[1]
out = root / 'native/assets/voices'
lines = [
    'Po velnių, jūs pažadinote mano įniršį!',
    'Prakeikti, jūs vis dar stovite prieš mane!',
    'Velnias, mano pyktis tik auga!',
    'Šūdas, dabar pajusite mano tikrąją galią!',
    'Eikite po velnių, niekas manęs nesustabdys!',
    'Kad jus kur perkūnas, aš dar nebaigiau!',
    'Po velnių, šis pasaulis sugrius kartu su jumis!',
    'Prakeikimas, jūs pažadinote paskutinę mano galią!',
]
FIRST_NEW_ID = 10


async def generate(text: str, tmp_mp3: Path) -> tuple[Path, int]:
    import edge_tts
    comm = edge_tts.Communicate(text, 'lt-LT-LeonasNeural', rate='-15%', pitch='-20Hz')
    await comm.save(str(tmp_mp3))
    # Godot streams MP3 directly; avoid machine-specific ffmpeg dependencies.
    return tmp_mp3, 24000


async def main():
    import tempfile
    provenance = out / 'boss-lithuanian-provenance.json'
    old_records = json.loads(provenance.read_text(encoding='utf-8')).get('lines', []) if provenance.exists() else []
    generated_ids = {f'boss_lt_{index}' for index in range(FIRST_NEW_ID, FIRST_NEW_ID + len(lines))}
    records = [record for record in old_records if record.get('id') not in generated_ids]
    for i, text in enumerate(lines, start=FIRST_NEW_ID):
        with tempfile.TemporaryDirectory() as td:
            tmp_mp3 = Path(td) / f'boss_lt_{i}.mp3'
            audio_path, sr = await generate(text, tmp_mp3)
            final_path = out / f'boss_lt_{i}.mp3'
            final_path.write_bytes(audio_path.read_bytes())
            duration = len(audio_path.read_bytes()) / 6000.0 # Edge TTS outputs 48 kbit/s MP3.
            records.append({
                'id': final_path.stem,
                'text': text,
                'language': 'lt',
                'duration': duration,
                'sha256': hashlib.sha256(final_path.read_bytes()).hexdigest()
            })
            print(f'{text} {duration:.2f}s')
    records.sort(key=lambda record: int(record['id'].rsplit('_', 1)[-1]))
    provenance.write_text(
        json.dumps({'engine': 'edge-tts lt-LT-LeonasNeural, native Lithuanian TTS', 'lines': records}, ensure_ascii=False, indent=2), encoding='utf-8'
    )


if __name__ == '__main__':
    asyncio.run(main())
