# make_index.py
from pathlib import Path
import html
import sys


def build_index(target_dir: str, suffix: str, title: str) -> None:
    """
    target_dir 配下の *.suffix を列挙して、フォルダごとに
    index.html を作成する。
    """
    root = Path(target_dir).resolve()
    if not root.is_dir():
        print(f"[WARN] TargetDir not found: {root}", file=sys.stderr)
        return

    files = sorted(root.rglob(f"*.{suffix}"))
    if not files:
        print(f"[WARN] No *.{suffix} under {root}", file=sys.stderr)
        return

    # groups[beamline] = [relative_path_str, ...]
    groups: dict[str, list[str]] = {}
    root_key = "その他"

    for f in files:
        rel = f.relative_to(root).as_posix() 
        parts = rel.split("/")

        if len(parts) > 1:
            beam = parts[0]  # 各フォルダ
        else:
            beam = root_key  # 直下ファイル

        groups.setdefault(beam, []).append(rel)

    # HTML を 1 行ずつ積む
    lines: list[str] = []

    lines.append("<!DOCTYPE html>")
    lines.append('<html lang="ja">')
    lines.append("<head>")
    lines.append('  <meta charset="UTF-8" />')
    lines.append(f"  <title>{html.escape(title)}</title>")
    lines.append("  <style>")
    lines.append('    body { font-family: "Yu Gothic", YuGothic, "Helvetica Neue", Arial, sans-serif;')
    lines.append("           background-color: #f9f9f9; color: #333; max-width: 900px;")
    lines.append("           margin: 0 auto; padding: 2rem; line-height: 1.6; }")
    lines.append("    h1 { font-size: 1.8rem; border-bottom: 2px solid #0056b3;")
    lines.append("         padding-bottom: 0.5rem; color: #0056b3; }")
    lines.append("    h2 { font-size: 1.1rem; margin-top: 1.5rem; border-bottom: 1px solid #ddd; }")
    lines.append("    ul { list-style-type: none; padding-left: 1rem; }")
    lines.append("    li { margin: 2px 0; }")
    lines.append("    a  { text-decoration: none; color: #333; }")
    lines.append("    a:hover { color: #0056b3; }")
    lines.append("  </style>")
    lines.append("</head>")
    lines.append("<body>")
    lines.append(f"  <h1>{html.escape(title)}</h1>")

    # フォルダ別処理
    for beam in sorted(groups.keys()):
        esc_beam = html.escape(beam)
        lines.append(f"  <h2>{esc_beam}</h2>")
        lines.append("  <ul>")

        for rel in sorted(groups[beam]):
            esc_rel = html.escape(rel)

            # 拡張子なしで一つ下の階層ファイル名表示
            if beam == root_key:
                rel_for_disp = rel
            else:
                rel_for_disp = rel[len(beam) + 1 :]

            p = Path(rel_for_disp)
            # 「サブフォルダ/ファイル名(拡張子なし)」の形にする
            if p.parent == Path("."):
                disp = p.stem
            else:
                disp = str(p.parent / p.stem)

            lines.append(f'    <li><a href="{esc_rel}">{html.escape(disp)}</a></li>')

        lines.append("  </ul>")

    lines.append("</body>")
    lines.append("</html>")

    index_path = root / "index.html"
    index_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"[INFO] Index generated: {index_path}")


def main() -> None:
    if len(sys.argv) != 4:
        print("Usage: python make_index.py <TargetDir> <Suffix> <Title>", file=sys.stderr)
        sys.exit(1)

    target_dir = sys.argv[1]
    suffix = sys.argv[2]
    title = sys.argv[3]
    build_index(target_dir, suffix, title)


if __name__ == "__main__":
    main()
