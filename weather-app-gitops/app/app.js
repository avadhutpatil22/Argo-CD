const API_KEY = '2e960445e8994eab7b698e7041488dcf';

async function fetchWeather(city) {
  clearError();

  if (!city.trim()) {
    showError('Please enter a city name.');
    return;
  }

  try {
    const url = `${BASE_URL}?q=${encodeURIComponent(city)}&appid=${API_KEY}&units=metric`;

    const res = await fetch(url);

    if (!res.ok) {
      const errData = await res.json();
      console.error("API ERROR:", errData);

      if (res.status === 404) showError(`City "${city}" not found.`);
      else if (res.status === 401) showError(`Invalid API key: ${errData.message}`);
      else showError(`Error ${res.status}: ${errData.message}`);
      return;
    }

    const data = await res.json();
    lastData = data;
    renderWeather(data);

  } catch (e) {
    console.error(e);

    if (!API_KEY || API_KEY === '2e960445e8994eab7b698e7041488dcf') {
      renderDemo(city);
    } else {
      showError('Network error. Check your connection.');
    }
  }
}
