export async function correctText(text) {
  const response = await fetch('/correct', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });

  if (!response.ok) {
    throw new Error(`Сервер вернул ошибку ${response.status} ${response.statusText}.`);
  }

  const data = await response.json();
  return { corrected: data.corrected, elapsedStr: data.elapsed_seconds_str };
}
