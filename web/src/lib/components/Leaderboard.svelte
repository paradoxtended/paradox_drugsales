<script lang="ts">
import { dataState, NuiState, nuiState } from "$lib/utils";

interface LeaderboardProps {
    imageUrl: string;
    nickname: string;
    users: {
        name: string;
        nickname: string;
        imageUrl: string;
        stats: { earned: number; drugsSold: number; mostSellable: string; }
    }[]
}

let data: LeaderboardProps = $dataState as unknown as LeaderboardProps;

</script>

{#if $nuiState === NuiState.Leaderboard}
    <div class="leaderboard-container">
        <div class="leaderboard-wrapper p-5 pr-0">
            <div class="flex items-center justify-between pr-5">
                <div>
                    <p class="text-white text-2xl">Drug Dealers</p>
                    <p class="text-neutral-500 font-[Inter] text-sm">Take a look at dealers of this city</p>
                </div>
                <div class="text-white flex items-center gap-3">
                    <p class="text-lg">Welcome, <span class="font-bold text-lime-500">{data.nickname}</span></p>
                    <div class="outline outline-2 rounded-full outline-offset-2 group cursor-pointer relative">
                        <img src={data.imageUrl} alt="user-profile"
                        class="rounded-full w-[50px] h-[50px] group-hover:opacity-50 transition-all">
                        <i class="hgi hgi-stroke hgi-edit-02 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white opacity-0 group-hover:opacity-100 transition-all"></i>
                    </div>
                </div>
            </div>
            <div class="my-3 relative pr-5">
                <input type="text" placeholder="Search..."
                class="bg-transparent placeholder:text-neutral-500 text-white font-[Inter] text-sm border border-neutral-700 rounded-md px-2 py-1 w-full
                focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-neutral-300">
                <i class="hgi hgi-stroke hgi-search-01 text-neutral-500 absolute top-1/2 right-5 -translate-x-1/2 -translate-y-1/2 pointer-events-none"></i>
            </div>
            {#if data.users.length === 0}
                <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-lg flex items-center gap-3">
                    <i class="hgi hgi-stroke hgi-user-question-02 text-3xl"></i>
                    <p class="font-[Inter]">No user found.</p>
                </div>
            {/if}
        </div>
    </div>
{/if}