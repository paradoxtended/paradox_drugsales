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
            earned: 688421,
            lastActive: '08/16/2025, 03:27:45 PM',
            reputation: 24.564
          },
          drugs: {
            meth_bag: { label: 'Meth Bag', amount: 48 },
            coke_bag: { label: 'Coke Bag', amount: 75 },
            meth_syringe: { label: 'Meth Syringe', amount: 92 },
            coke_brick: { label: 'Coke Brick', amount: 150 }
          },
          myself: true
        },
        {
          name: 'Esteban Casados',
          nickname: 'Esteee',
          imageUrl: 'https://i.postimg.cc/BQ08mBGj/Sunset-in-Grace-Bay-Turks-and-Caicos-Islands-scaled.jpg',
          stats: {
            earned: 184752,
            lastActive: '08/14/2025, 02:27:48 PM',
            reputation: 12.4516
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

/*
debugData([
  {
    action: 'hustle',
    data: {
      items: [
        { label: 'Meth Bag', amount: 1, price: 48 }
      ],
      rep: 0.56,
      renegotiate: true
    }
  }
])
*/

/*
debugData([
  {
    action: 'openDrugsale',
    data: {
      itemLabel: 'Meth Bag',
      amount: 15,
      price: { min: 110, max: 180 },
      rep: 1.54
    }
  }
])
*/

useNuiEvent('openDrugsale', (data) => {
  dataState.set(data);
  nuiState.set(NuiState.Main);
})

useNuiEvent('hustle', (data) => {
  dataState.set(data);
  nuiState.set(NuiState.Wholesale);
})

useNuiEvent('leaderboard', (data) => {
  dataState.set(data);
  nuiState.set(NuiState.Leaderboard);
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
  {#if $nuiState === NuiState.Main} <Main bind:selectedPrice /> {/if}
  {#if $nuiState === NuiState.Wholesale} <Wholesale /> {/if}
  {#if $nuiState === NuiState.Leaderboard} <Leaderboard /> {/if}
{/if}