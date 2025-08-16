<script lang="ts">
import { dataState, NuiState, nuiState } from "$lib/utils";
import { linear } from "svelte/easing";
import { fade } from "svelte/transition";

interface User {
    name: string;
    nickname: string;
    imageUrl?: string;
    stats: { 
        earned: number;
        lastActive: string;
    },
    drugs: Record<string, { label: string, amount: number }>;
    myself?: boolean;
}

interface LeaderboardProps {
    users: User[];
    admin?: boolean;
}

let data: LeaderboardProps = $state($dataState as unknown as LeaderboardProps);
let activeTab: 'PROFILE' | 'LEADERBOARD' = $state('LEADERBOARD');
let users: User[] = $state([]);
let query: string = $state('');
let player: User = data.users.find(user => user?.myself) ?? data.users[0];
let currentProfile: User | undefined = $state();

let categoriesEl: HTMLElement | undefined = $state();
let bgSliderEl: HTMLElement | undefined = $state();
let sliderEl: HTMLElement | undefined = $state();

function updateSlider() {
    if (!categoriesEl || !bgSliderEl || !sliderEl) return;

    const pEls = categoriesEl.querySelectorAll('p');
    const activeEl = Array.from(pEls).find(el => el.classList.contains('active')) as HTMLElement;
    if (!activeEl) return;

    const rect = activeEl.getBoundingClientRect();
    const containerRect = categoriesEl.getBoundingClientRect();

    const width = rect.width;
    const offsetLeft = rect.left - containerRect.left;

    bgSliderEl.style.width = width + 'px';
    bgSliderEl.style.transform = `translateX(${offsetLeft}px)`;

    sliderEl.style.width = width + 'px';
    sliderEl.style.transform = `translateX(${offsetLeft}px)`;
}

$effect(() => {
    if (activeTab) {
        updateSlider();
    }

    users = data.users
        .filter(user =>
            user.nickname.toLowerCase().includes(query.toLowerCase()) ||
            user.name.toLowerCase().includes(query.toLowerCase()) && data.admin)
        .sort((a, b) => b.stats.earned - a.stats.earned)
});

function getDrugs(drugs: Record<string, { label: string, amount: number }>) {
    const allDrugs = Object.values(drugs);
    const sorted = allDrugs.sort((a, b) => b.amount - a.amount);

    return sorted.slice(0, 3).map(drug => drug.label).join(', ')
}

function openProfile(user?: User) {
    const profile = user || player;
    
    if (profile === null) return;

    activeTab = 'PROFILE';
    currentProfile = profile;
}

</script>

{#if $nuiState === NuiState.Leaderboard}
    <div class="lb-container" transition:fade|global>
        <!-- Main tab (header) -->
        <div class="flex items-center justify-between">
            <div class="lb-title-container">
                <p class="text-[#2dd4bf] font-medium text-xl drop-shadow-[0_0_10px_#2dd4bf] leading-6">Drug Dealers</p>
                <p class="text-sm text-gray-400">Find dealers</p>
            </div>
            <div class="flex items-center relative" bind:this={categoriesEl}>
                <p class="lb-category" class:active={activeTab === 'LEADERBOARD'} onclick={() => activeTab = 'LEADERBOARD'}>LEADERBOARD</p>
                <p class="lb-category" class:active={activeTab === 'PROFILE'} onclick={() => openProfile()}>PROFILE</p>
                <div class="lb-category-bg-slider" bind:this={bgSliderEl}></div>
                <div class="lb-category-slider" bind:this={sliderEl}></div>
            </div>
            <div class="relative">
                <input type="text" placeholder="Search" class="lb-input-search" bind:value={query}>
                <i class="hgi hgi-stroke hgi-search-01 text-[#adadad] absolute top-1/2 -translate-y-1/2 right-3 text-sm pointer-events-none"></i>
            </div>
            <div class="flex items-center text-[13px] text-gray-400 bg-gray-500/30 p-[1px]">
                <p class="bg-gray-800/50 px-2 py-0.5">Exit</p>
                <p class="px-2 py-0.5">ESC</p>
            </div>
        </div>

        <div class="lb-divider after:-bottom-[9px] z-0"></div>

        <!-- Leaderboard -->
        {#if activeTab === 'LEADERBOARD'}
            <div in:fade={{ duration: 300, easing: linear }}
            class="mt-5 overflow-auto h-[400px] -mr-[15px] pr-[15px]">
                <table class="w-full border-separate" style="border-spacing: 0 10px;">
                    <thead>
                        <tr class="text-[#9ca3af] text-sm bg-gradient-to-b from-neutral-500/0 to-[#4b556350]">
                            <td class="text-center py-1.5">User</td>
                            <td class="text-center py-1.5">Last active</td>
                            <td class="text-center py-1.5">Most sellable drugs</td>
                            <td class="text-center py-1.5">Earnings</td>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td colspan="4">
                                <div class="lb-divider"></div>
                            </td>
                        </tr>
                        {#each users as user}
                            <tr class="text-sm text-white bg-[radial-gradient(#71717a75,_#374151a0)]">
                                <td class="text-center p-2">
                                    <div class="flex items-center gap-5">
                                        <i class="fa-solid fa-user bg-gray-500/50 w-8 h-8 flex items-center justify-center rounded-sm duration-200
                                        hover:bg-[#2dd4bf20] hover:text-[#2dd4bf] cursor-pointer"
                                        onclick={() => openProfile(user)}></i>
                                        <p>{user.nickname}</p>
                                    </div>
                                </td>
                                <td class="text-center p-2">{user.stats.lastActive}</td>
                                <td class="text-center p-2">{getDrugs(user.drugs)}</td>
                                <td class="text-center p-2">{Intl.NumberFormat('en-US', { style: "currency", currency: 'USD', maximumFractionDigits: 0 }).format(user.stats.earned)}</td>
                            </tr>
                        {/each}
                    </tbody>
                </table>
            </div>
        {/if}

        <!-- Profile -->
        {#if activeTab === 'PROFILE' && currentProfile !== undefined}
            <div in:fade={{ duration: 300, easing: linear }} class="mt-7">
                <div class="flex items-center gap-3">
                    <div class="relative w-[100px] h-[115px]">
                        <!-- Hexagon border -->
                        <div class="absolute inset-0 hexagon"></div>
                        <!-- Image -->
                        <img src={currentProfile.imageUrl} class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[92%] h-[92%]" style="clip-path: polygon(50% 0,100% 25%,100% 75%,50% 100%,0% 75%,0% 25%); aspect-ratio: cos(30deg);" />
                    </div>
                    <div>
                        <p class="text-white text-2xl leading-5">{currentProfile.nickname}</p>
                        <p class="text-[15px] text-gray-400 font-light">Last active: {currentProfile.stats.lastActive}</p>
                    </div>
                </div>
            </div>
        {/if}
    </div>
{/if}