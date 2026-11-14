"""Arek Kuliner — AI agent pemandu kuliner Surabaya.

Agent ini sengaja dibuat sederhana: 3 tool dengan data dummy.
Tool `cek_antrian` sengaja dibuat LAMBAT (1-4 detik) supaya kita punya
"masalah latency" yang bisa dicari lewat Cloud Trace di sesi workshop.
"""

import os
import random
import time

from google.adk.agents import Agent

# Data dummy — tidak perlu database supaya fokus ke deployment & tracing.
KULINER = {
    "pusat": [
        {"nama": "Rawon Setan", "menu": "Rawon", "harga": 35000},
        {"nama": "Lontong Balap Garuda", "menu": "Lontong balap", "harga": 20000},
    ],
    "timur": [
        {"nama": "Bebek Sinjay Kenjeran", "menu": "Bebek goreng", "harga": 40000},
        {"nama": "Sate Klopo Ondomohen", "menu": "Sate klopo", "harga": 45000},
    ],
    "barat": [
        {"nama": "Rujak Cingur Genteng", "menu": "Rujak cingur", "harga": 30000},
        {"nama": "Tahu Tek Pak Jayen", "menu": "Tahu tek", "harga": 18000},
    ],
}


def cari_kuliner(area: str) -> dict:
    """Mencari rekomendasi tempat makan di suatu area Surabaya.

    Args:
        area: Area di Surabaya. Pilihan: "pusat", "timur", atau "barat".

    Returns:
        dict berisi status dan daftar tempat makan.
    """
    area = area.lower().strip()
    if area not in KULINER:
        return {
            "status": "error",
            "pesan": f"Area '{area}' tidak dikenal. Pilih: pusat, timur, barat.",
        }
    return {"status": "success", "area": area, "tempat": KULINER[area]}


def cek_antrian(nama_tempat: str) -> dict:
    """Mengecek perkiraan lama antrian di sebuah tempat makan.

    Args:
        nama_tempat: Nama tempat makan, contoh "Rawon Setan".

    Returns:
        dict berisi status dan perkiraan antrian dalam menit.
    """
    # Simulasi API pihak ketiga yang lambat -> akan terlihat jelas di Cloud Trace.
    time.sleep(random.uniform(1.0, 4.0))
    return {
        "status": "success",
        "nama_tempat": nama_tempat,
        "antrian_menit": random.randint(5, 45),
    }


def hitung_budget(total_harga: int, jumlah_orang: int) -> dict:
    """Menghitung biaya patungan per orang (sudah termasuk pajak 10%).

    Args:
        total_harga: Total harga makanan dalam Rupiah.
        jumlah_orang: Jumlah orang yang patungan.

    Returns:
        dict berisi status dan biaya per orang.
    """
    if jumlah_orang <= 0:
        return {"status": "error", "pesan": "jumlah_orang harus lebih dari 0."}
    per_orang = round(total_harga * 1.1 / jumlah_orang)
    return {"status": "success", "per_orang": per_orang}


root_agent = Agent(
    name="kuliner_agent",
    model=os.getenv("MODEL", "gemini-3.5-flash"),
    description="Pemandu kuliner Surabaya.",
    instruction=(
        "Kamu adalah 'Arek Kuliner', pemandu kuliner Surabaya yang ramah. "
        "Jawab dalam Bahasa Indonesia yang santai. "
        "Gunakan tool cari_kuliner untuk rekomendasi tempat, cek_antrian untuk "
        "info antrian, dan hitung_budget untuk menghitung patungan. "
        "Jangan mengarang data di luar hasil tool."
    ),
    tools=[cari_kuliner, cek_antrian, hitung_budget],
)
