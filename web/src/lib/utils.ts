import { fetchNui } from "./utils/fetchNui";
import { writable } from "svelte/store";

export enum NuiState {
  Closed = 0,
  Main = 1,
  Wholesale = 2,
  Leaderboard = 3
}

export const nuiState = writable(NuiState.Closed);
export const dataState = writable();

export const closeNui = (result?: 'confirmed' | 'negotiate' | boolean, price?: number) => {
    const wrapper = document.querySelector('.wrapper') as HTMLElement;
    const wholesaleWrapper = document.querySelector('.hustle-container') as HTMLElement;

    nuiState.set(NuiState.Closed);

    if (wrapper && price) {
        fetchNui('closeDrugsale', {
            sold: result,
            price: price
        });
    } else if (wholesaleWrapper) {
        fetchNui('hustle', result);
    } else {
        fetchNui('closeUI');
    }
}