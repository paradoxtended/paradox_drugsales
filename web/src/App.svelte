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
      imageUrl: 'https://i.postimg.cc/Mpg8Mb2K/walterwhite-wide-24664a3dc903dff3bf3fe17a27996d6a174ee50b.jpg',
      nickname: 'Walter',
      users: [
        //{ name: 'Esteban Casados', nickname: 'Walter', imageUrl: 'https://i.postimg.cc/Mpg8Mb2K/walterwhite-wide-24664a3dc903dff3bf3fe17a27996d6a174ee50b.jpg', stats: { earned: 487541, drugsSold: 184, mostSellable: 'Meth Syringe, Meth Bag' } },
      ]
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