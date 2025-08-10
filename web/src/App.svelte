<script lang="ts">
import { useNuiEvent } from '$lib/hooks/useNuiEvents';
import { debugData } from '$lib/utils/debugData';
import { fetchNui } from '$lib/utils/fetchNui';
import { isEnvBrowser } from '$lib/utils/misc';

interface Drugsale {
  itemLabel: string;
  amount: number;
  price: { min: number; max: number };
  rep: number;
}

let drug: Drugsale | undefined = $state();
let visible: boolean = $state(false); // Main (classic) offering system
let bulkVisible: boolean = $state(false);
let selectedPrice: number = $state(0);

let hideMin = $state(false);
let hideMax = $state(false);

$effect(() => {
  if (!drug) {
    hideMin = false;
    hideMax = false;
    return;
  }

  const percent = (selectedPrice - drug.price.min) / (drug.price.max - drug.price.min);
  hideMin = percent < 0.13;
  hideMax = percent > 0.87;
});

/*
debugData<Drugsale>([
  {
    action: 'openDrugsale',
    data: {
      itemLabel: 'Meth',
      amount: 3,
      rep: 5.42,
      price: {
        min: 116,
        max: 145
      }
    }
  }
])
*/

debugData([
  {
    action: 'openBulkSale',
    data: {
      itemLabel: 'Coke',
      amount: 52,
      price: 75
    }
  }
])

useNuiEvent('openDrugsale', (data: Drugsale) => {
  drug = data;
  selectedPrice = (data.price.min + data.price.max) / 2;
  visible = true;
})

useNuiEvent('openBulkSale', (data: Drugsale) => {
  drug = data;
  bulkVisible = true;
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

function closeNui(sold?: boolean, price?: number) {
  const wrapper = document.querySelector('.wrapper') as HTMLElement;
  const repWrapper = document.querySelector('.rep-wrapper') as HTMLElement;

  if (wrapper) wrapper.style.animation = 'slideOut 250ms forwards';
  if (repWrapper) repWrapper.style.animation = 'repAnimOut 250ms forwards';

  setTimeout(() => {
    visible = false;
    bulkVisible = false;
  }, 250);

  fetchNui('closeDrugsale', {
    sold: sold,
    price: price || selectedPrice
  })
}

function onKeyDown(event: KeyboardEvent) {
  const key = event.key.toLowerCase();

  switch (key) {
    case 'escape':
      return closeNui();
    case 'e':
      return visible ? closeNui(true) : closeNui(true, (drug?.price as unknown as number));
    case 'q':
      return bulkVisible && closeNui();
  }
}
</script>

<svelte:window onkeydown={onKeyDown} />

{#if visible}
  <div class="rep-wrapper">
    <p>YOUR REPUTATION:</p>
    <div class="relative">
      <div class="rep-shape"></div>
      <p class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-sm">{Number(drug?.rep.toFixed(2)).toString()}</p>
    </div>
  </div>
  <div class="text-white w-[565px] absolute top-[80%] left-1/2 -translate-x-1/2 -translate-y-1/2 flex justify-center items-center flex-col gap-3 wrapper">
    <p class="text-lg">SELECT THE PRICE YOU WANT TO OFFER.</p>
    <p class="text-4xl text-center">CLIENT IS OFFERING TO PURCHASE {drug?.amount} {drug?.itemLabel.toUpperCase()}</p>
    <div class="w-4/5 mt-3 flex flex-col gap-5 relative">
      <div class="flex items-center justify-between text-neutral-300">
        <p>{#if !hideMin}${drug?.price.min.toFixed(2)}{/if}</p>
        <p>{#if !hideMax}${drug?.price.max.toFixed(2)}{/if}</p>
      </div>

      <!-- Value above thumb -->
      <div class="absolute text-lime-500 pointer-events-none"
          style="left: calc(((100% - 1rem) * (({selectedPrice} - {drug?.price.min}) / ({drug?.price.max} - {drug?.price.min}))) + 0.5rem); transform: translateX(-50%);">
        ${selectedPrice.toFixed(0)}
      </div>

      <input 
        type="range" 
        min={drug?.price.min} 
        max={drug?.price.max}
        bind:value={selectedPrice}
        class="w-full h-3 bg-black/65 rounded-full outline outline-1 outline-neutral-700/65 appearance-none cursor-pointer
         [&::-webkit-slider-thumb]:appearance-none
         [&::-webkit-slider-thumb]:w-3
         [&::-webkit-slider-thumb]:h-8
         [&::-webkit-slider-thumb]:bg-lime-500
         [&::-webkit-slider-thumb]:rounded
         [&::-webkit-slider-thumb]:drop-shadow-[0_0_10px_#84cc16]">
    </div>
    <p class="text-xl mt-7">PRESS <span class="bg-neutral-500/50 px-3 py-0.5 rounded border border-neutral-300/75">E</span> TO CONFIRM THE SALE.</p>
  </div>
{/if}

{#if bulkVisible}
  <div class="text-white w-[565px] absolute top-[80%] left-1/2 -translate-x-1/2 -translate-y-1/2 flex justify-center items-center flex-col gap-3 wrapper">
    <p class="text-lg">DECIDE WHETHER YOU AGREE TO THE DEAL.</p>
    <p class="text-4xl text-center">CLIENT IS OFFERING TO PURCHASE {drug?.amount} {drug?.itemLabel.toUpperCase()}</p>
    <p class="text-2xl">
      CLIENT IS OFFERING
      <span class="text-lime-500 drop-shadow-[0_0_10px_#84cc16]">
        ${Number((drug?.price as unknown as number).toFixed(2)).toLocaleString('en-US')}
      </span>
      PER BAG
    </p>
    <div class="flex items-center gap-3 w-3/4">
      <div class="flex justify-center py-2 items-center gap-3 w-full bg-red-500/20 border border-red-800 rounded-md">
        <p class="bg-black/50 px-2">Q</p>
        <p>DISAGREE</p>
      </div>
      <div class="flex justify-center py-2 items-center gap-3 w-full bg-lime-500/20 border border-lime-800 rounded-md">
        <p class="bg-black/50 px-2">E</p>
        <p>AGREE</p>
      </div>
    </div>
  </div>
{/if}