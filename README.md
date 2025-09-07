# <center>Krishi AI Sahayak
<center><img src="https://i.imghippo.com/files/BIeo4080M.jpg" alt="App Logo" width="200"/></center>

<center>An app that unifies multiple platforms to serve as a single stop solution to all the needs that a farmer can have, servicable via API or android application.</center>

## App Preview
<table>
  <tr>
    <td>
      <img src="https://i.imghippo.com/files/QcQ4158Ngw.jpg" alt="ss1" width="300"/>
    </td>
    <td>
      <img src="https://i.imghippo.com/files/FGaL2314KdM.jpg" alt="ss2" width="300"/>
    </td>
  </tr>
</table>



### Available and Planned Features:
- Integrates with readily available commercial IOT sensors to retrieve soil data.
- Automatically retrieves latitude and longitude to dispense real time weather data.
- Provides soil recommendation based on soil and weather conditions.
    - Verifies against [Ecocrop](https://github.com/OpenCLIM/ecocrop/blob/main/EcoCrop_DB.csv) and [Soil-grid](https://www.isric.org/explore/soilgrids).
- Ranks against existing data on yields per hectare, and price in INR per hectare from [Agritech.](https://agritech.tnau.ac.in/agriculture/agri_costofcultivation_indexpage12.html)
- Analysis on neighbouring crop patterns to avoid surplus-caused price drops and adhere to market safety.
- LLM powered guide for further assistance and to aid in answering queries.
- Provides list of verified Government authorised wholesalers to cut out loss incurred due to middlemen.
### Usage:
- Download APK from [Github Releases.](https://github.com/Eros483/SIH25-Farmers/releases)
- Utilise [API](https://sih25-farmers.onrender.com/) for retrieving information and integration with other applications.

### Developer Usage:
```
git clone https://github.com/Eros483/SIH25-Farmers.git
cd SIH25-Farmers
pip install -e .
```

### Current Constraints
- Planned usage of openAI-whisper for STT and TTS.
- Render free tier usage.
- Translation services rate-limited while debugging.
- Planned future integration with authorised datasets with real-time information.

