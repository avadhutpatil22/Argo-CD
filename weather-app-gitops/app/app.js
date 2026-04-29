async function fetchWeather(city) {
  clearError();

  if (!city.trim()) {
    showError('Please enter a city name.');
    return;
  }

  // 👉 Skip API call if using demo key
  if (API_KEY === '2e960445e8994eab7b698e7041488dcf') {
    renderDemo(city);
    return;
  }

  try {
    const url = `${BASE_URL}?q=${encodeURIComponent(city)}&appid=${API_KEY}&units=metric`;
    const res = await fetch(url);

    if (!res.ok) {
      if (res.status === 404) showError(`City "${city}" not found.`);
      else if (res.status === 401) showError('Invalid API key — see app.js to configure.');
      else showError(`Error ${res.status}: please try again.`);
      return;
    }

    const data = await res.json();
    lastData = data;
    renderWeather(data);

  } catch (e) {
    showError('Network error. Check your connection.');
  }
}
