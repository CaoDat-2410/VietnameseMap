"""Probe HuggingFace dataset structure."""
from datasets import load_dataset

for subset in ["provinces", "communes", "committees"]:
    ds = load_dataset("tmquan/sapnhap-bando-vn", subset, trust_remote_code=True)["train"]
    print(f"\n=== {subset} ({len(ds)} rows) ===")
    print("Columns:", list(ds.features.keys()))
    print("Sample row:")
    row = ds[0]
    for k, v in row.items():
        print(f"  {k} = {repr(v)[:120]}")
    print("Second row (if available):")
    if len(ds) > 1:
        row2 = ds[1]
        for k, v in row2.items():
            print(f"  {k} = {repr(v)[:120]}")
