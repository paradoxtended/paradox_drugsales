<script lang="ts">
import { closeNui, dataState, NuiState, nuiState } from "$lib/utils";
import { fade, scale } from "svelte/transition";

interface Hustle {
  items: {
    label: string;
    price: number;
    amount: number;
  }[],
  rep: number;
  renegotiate?: boolean;
}

let hustle: Hustle = $dataState as unknown as Hustle;
</script>

{#if $nuiState === NuiState.Wholesale}
  <div class="rep-wrapper" transition:scale|global>
    <p>YOUR REPUTATION:</p>
    <div class="relative">
      <div class="rep-shape"></div>
      <p class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-sm">{Number(hustle.rep.toFixed(2)).toString()}</p>
    </div>
  </div>
  <div class="hustle-container" transition:fade|global>
    <div class="text-white w-[565px] absolute top-[80%] left-1/2 -translate-x-1/2 -translate-y-1/2 flex justify-center items-center flex-col gap-3">
      <p class="text-lg text-lime-500">OFFER</p>
      <p class="text-4xl text-center">
        {hustle.items.reduce((sum, item) => sum + (item.price * item.amount), 0).toFixed(0)} BILLS FOR
        {hustle.items.reduce((sum, item) => sum + item.amount, 0).toFixed(0)} ITEMS
      </p>
      <p class="text-neutral-400 font-[Inter] text-sm text-center">
        {#each hustle.items as item, i}
          <span style="white-space: nowrap;">
            {item.amount}x {item.label} for {item.price * item.amount} bills
          </span>{i < hustle.items.length - 1 ? ', ' : ''}
        {/each}
      </p>
    </div>

    <div class="absolute w-[65%] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 flex items-center justify-between text-white">
      <button class="bg-black/50 w-[300px] text-start text-lg px-7 py-3 rounded-lg border border-neutral-600 hover:bg-black/30 transition-all duration-300"
      onclick={() => closeNui(false)}>
        DECLINE OFFER
      </button>

      <div class="flex flex-col gap-3">
        <button class="bg-black/50 w-[300px] text-start text-lg px-7 py-3 rounded-lg border border-neutral-600 hover:bg-black/30 transition-all duration-300"
        onclick={() => closeNui('confirmed')}>
          ACCEPT OFFER
        </button>

        {#if hustle.renegotiate}
          <button class="bg-black/50 w-[300px] text-start text-lg px-7 py-3 rounded-lg border border-neutral-600 hover:bg-black/30 transition-all duration-300"
          onclick={() => closeNui('negotiate')}>
            NEGOTIATE
            <p class="text-neutral-400 font-[Inter] text-sm">Renegotiate the prices.</p>
          </button>
        {/if}
      </div>
    </div>
  </div>
{/if}