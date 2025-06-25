<script>
document.addEventListener("DOMContentLoaded", () => {
  // pタグ内でimgしか含まれてないような段落を image-row に変換
  document.querySelectorAll("p").forEach(p => {
    const imgs = p.querySelectorAll("img");
    // 条件をゆるめて img が2つ以上あれば変換する（必要なら1つでもOK）
    if (imgs.length > 0 && [...p.childNodes].every(n => n.nodeType === 3 || n.tagName === "IMG")) {
      const div = document.createElement("div");
      div.className = "image-row";
      imgs.forEach(img => div.appendChild(img.cloneNode(true)));
      p.replaceWith(div);
    }
  });

  // モーダル生成
  const modal = document.createElement("div");
  modal.id = "img-modal";
  modal.innerHTML = '<img src="" alt="">';
  Object.assign(modal.style, {
    display: "none",
    position: "fixed",
    top: 0, left: 0, right: 0, bottom: 0,
    background: "rgba(0,0,0,0.85)",
    zIndex: "9999",
    justifyContent: "center",
    alignItems: "center"
  });
  modal.style.display = "none";
  modal.style.flexDirection = "column";
  modal.style.justifyContent = "center";
  modal.style.alignItems = "center";

  const modalImg = modal.querySelector("img");
  Object.assign(modalImg.style, {
    maxWidth: "90%",
    maxHeight: "90%",
    cursor: "zoom-out",
    boxShadow: "0 0 20px black"
  });

  document.body.appendChild(modal);

  document.body.addEventListener("click", e => {
    if (e.target.closest(".image-row") && e.target.tagName === "IMG") {
      modalImg.src = e.target.src;
      modal.style.display = "flex";
    } else if (e.target === modal || e.target === modalImg) {
      modal.style.display = "none";
    }
  });
});
</script>
