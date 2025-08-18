<script lang="ts">
import { dataState, NuiState, nuiState } from "$lib/utils";
import { fetchNui } from "$lib/utils/fetchNui";
import { linear } from "svelte/easing";
import { fade, slide } from "svelte/transition";

interface User {
    identifier: string;
    name: string;
    nickname: string;
    imageUrl?: string;
    stats: { 
        earned: number;
        lastActive: string;
        reputation: number;
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
let currentSetting: 'nickname' | 'imageUrl' | null = $state(null);

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
    const allDrugs = Object.values(drugs).filter(drug => drug.amount > 0);
    const sorted = allDrugs.sort((a, b) => b.amount - a.amount);

    return sorted.length > 0 ? [
        sorted.slice(0, 3).map(drug => drug.label).join(', '), 
        sorted.map(drug => `${drug.label}: ${drug.amount}`).join(', ')
    ] : [
        'No drugs sold',
        'No drugs sold'
    ]
}

function openProfile(user?: User) {
    const profile = user || player;
    
    if (profile === null) return;

    currentSetting = null;
    activeTab = 'PROFILE';
    currentProfile = profile;
}

async function editProfile() {
    const input = (document.getElementById('setting-input') as HTMLInputElement).value;
    
    if (input === null || input === '' || currentSetting === null || currentProfile === undefined) return;

    const response = await fetchNui('editProfile', { identifier: currentProfile.identifier, type: currentSetting, input: input });

    if (response) {
        data.users = data.users.map(user => {
            if (user.identifier === currentProfile!.identifier) {
                return {
                    ...user,
                    [currentSetting!]: input
                }
            }

            return user
        });

        player[currentSetting!] = input;

        currentProfile = {
            ...currentProfile,
            [currentSetting]: input
        }
    }

    currentSetting = null;
}

</script>

{#if $nuiState === NuiState.Leaderboard}
    <div class="lb-container" transition:fade|global={{easing: linear}}>
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
                                <td class="text-center p-2">{getDrugs(user.drugs)[0]}</td>
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
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="relative w-[100px] h-[115px]">
                            <!-- Hexagon border -->
                            <div class="absolute inset-0 hexagon"></div>
                            <!-- Image -->
                            <img src={currentProfile.imageUrl} class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[92%] h-[92%]" style="clip-path: polygon(50% 0,100% 25%,100% 75%,50% 100%,0% 75%,0% 25%); aspect-ratio: cos(30deg);" />
                        </div>
                        <div>
                            <p class="text-white text-2xl flex items-center gap-3 group">
                                {currentProfile.nickname}
                                <span class="text-gray-400 text-lg font-light duration-300 opacity-0 group-hover:opacity-100">{data.admin || currentProfile.myself ? currentProfile.name : ''}</span>
                            </p>
                            <p class="text-sm text-gray-400 font-light">Last active: {currentProfile.stats.lastActive}</p>
                            <p class="text-sm text-gray-400 font-light">Reputation: {Number(currentProfile.stats.reputation.toFixed(2)).toString()}</p>
                        </div>
                    </div>
                    {#if currentProfile.myself || data.admin}
                        <div class="flex flex-col gap-2">
                            <button class="text-sm text-[#2dd4bf] font-light bg-[#2dd4bf20] py-[5px] px-[17px] duration-300 hover:bg-[#2dd4bf30] rounded-sm"
                            onclick={() => currentSetting = 'nickname'}>Change username</button>
                            <button class="text-sm text-[#2dd4bf] font-light bg-[#2dd4bf20] py-[5px] px-[17px] duration-300 hover:bg-[#2dd4bf30] rounded-sm"
                            onclick={() => currentSetting = 'imageUrl'}>Change profile picture</button>
                        </div>
                    {/if}
                </div>

                <div class="lb-divider pt-3"></div>

                <div class="overflow-auto h-[260px] -mr-[15px] pr-[15px] mt-3">
                    {#if currentSetting}
                        {#key currentSetting}
                            <div class="bg-[radial-gradient(#71717a75,_#374151a0)] p-3 mb-3 rounded-sm flex items-center justify-between" 
                                in:slide|global>
                                <div>
                                    <p class="text-[#2dd4bf] font-medium text-lg drop-shadow-[0_0_10px_#2dd4bf] leading-6">Change {currentSetting === 'imageUrl' ? 'profile picture' : 'nickname'}</p>
                                    <p class="text-sm text-gray-400">Change your {currentSetting === 'imageUrl' ? 'profile picture' : 'nickname'} to your likings.</p>
                                </div>
                                <div class="flex items-center gap-3">
                                    <input id="setting-input" type="text" placeholder={currentSetting === 'imageUrl' ? 'New profile picture' : 'New nickname'} class="lb-input-search" defaultValue={currentSetting === 'imageUrl' ? currentProfile.imageUrl : currentProfile.nickname}>
                                    <div class="relative w-[30px] h-[35px]">
                                        <!-- Hexagon border -->
                                        <div class="absolute inset-0 hexagon"></div>
                                        <div class="bg-[#2dd4bf20] w-full h-full cursor-pointer duration-300 hover:bg-[#2dd4bf30]"
                                        style="clip-path: polygon(50% 0,100% 25%,100% 75%,50% 100%,0% 75%,0% 25%); aspect-ratio: cos(30deg);"
                                        onclick={() => editProfile()}>
                                            <i class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 fa-solid fa-check text-[#2dd4bf]"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        {/key}
                    {/if}

                    <div class="bg-[radial-gradient(#71717a75,_#374151a0)] p-3 rounded-sm">
                        <div>
                            <p class="text-[#2dd4bf] font-medium text-lg drop-shadow-[0_0_10px_#2dd4bf] leading-6">Statistics</p>
                            <p class="text-sm text-gray-400">Check player's statistics.</p>
                        </div>
                        <div>
                            <table class="w-full border-separate" style="border-spacing: 0 10px;">
                                <thead>
                                    <tr class="text-[#9ca3af] text-sm bg-gradient-to-b from-neutral-500/0 to-[#4b556350]">
                                        <td class="text-center py-1.5">Reputation</td>
                                        <td class="text-center py-1.5">Earnings</td>
                                        <td class="text-center py-1.5">Sold drugs</td>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td colspan="4">
                                            <div class="lb-divider"></div>
                                        </td>
                                    </tr>
                                    <tr class="text-sm text-white bg-[radial-gradient(#71717a75,_#374151a0)]">
                                        <td class="text-center p-2">{Number(currentProfile.stats.reputation.toFixed(2)).toString()}</td>
                                        <td class="text-center p-2">{Intl.NumberFormat('en-US', { style: "currency", currency: 'USD', maximumFractionDigits: 0 }).format(currentProfile.stats.earned)}</td>
                                        <td class="text-center p-2 max-w-[150px]">{getDrugs(currentProfile.drugs)[1]}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        {/if}
    </div>
{/if}