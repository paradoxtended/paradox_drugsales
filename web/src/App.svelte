<script lang="ts">
import Leaderboard from '$lib/components/Leaderboard.svelte';
import Main from '$lib/components/Main.svelte';
import Wholesale from '$lib/components/Wholesale.svelte';
import { useNuiEvent } from '$lib/hooks/useNuiEvents';
import { closeNui, dataState, NuiState, nuiState } from '$lib/utils';
import { debugData } from '$lib/utils/debugData';
import { isEnvBrowser } from '$lib/utils/misc';

let selectedPrice = 0;

debugData([
  {
    action: 'leaderboard',
    data: {
      users: [
        {
          name: 'Enzo Favara',
          nickname: 'Enzoo',
          imageUrl: 'https://i.postimg.cc/8CCKvsRZ/Enzo-Favara.jpg',
          stats: {
            earned: 578421,
            lastActive: '08/16/2025, 03:27:45 PM'
          },
          drugs: {
            meth_bag: { label: 'Meth Bag', amount: 48 },
            coke_bag: { label: 'Coke Bag', amount: 75 },
            meth_syringe: { label: 'Meth Syringe', amount: 92 }
          },
          myself: true
        },
        {
          name: 'Esteban Casados',
          nickname: 'Esteee',
          imageUrl: 'https://i.postimg.cc/BQ08mBGj/Sunset-in-Grace-Bay-Turks-and-Caicos-Islands-scaled.jpg',
          stats: {
            earned: 184752,
            lastActive: '08/14/2025, 02:27:48 PM'
          },
          drugs: {
            weed_joint: { label: 'Weed Joint', amount: 41 },
            weed_bag: { label: 'Weed Bag', amount: 94 }
          }
        }
      ],
      admin: true
    }
  }
])

useNuiEvent('openDrugsale', (data) => {
  nuiState.set(NuiState.Main);
  dataState.set(data);
})

useNuiEvent('hustle', (data) => {
  nuiState.set(NuiState.Wholesale);
  dataState.set(data);
})

useNuiEvent('leaderboard', (data) => {
  nuiState.set(NuiState.Leaderboard);
  dataState.set(data);
})

if (isEnvBrowser()) {
  const root = document.getElementById('app');

  // https://i.imgur.com/iPTAdYV.png - Night time img
  // https://i.imgur.com/3pzRj9n.png - Day time img
  root!.style.backgroundImage = 'url("https://i.imgur.com/iPTAdYV.png")';
  root!.style.backgroundSize = 'cover';
  root!.style.backgroundRepeat = 'no-repeat';
  root!.style.backgroundPosition = 'center';
}

function onKeyDown(event: KeyboardEvent) {
  const key = event.key.toLowerCase();

  switch (key) {
    case 'escape':
      return closeNui();
    case 'e':
      return $nuiState === NuiState.Main && closeNui(true, selectedPrice);
  }
}
</script>

<svelte:window onkeydown={onKeyDown} />

{#if $nuiState !== NuiState.Closed}
  <Main bind:selectedPrice />
  <Wholesale />
  <Leaderboard />
{/if}