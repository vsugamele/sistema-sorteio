import { supabase } from './supabase';

export async function uploadExampleReceipt(imageUrl: string) {
  try {
    // Fetch the image
    const response = await fetch(imageUrl);
    const blob = await response.blob();

    // Upload to Supabase storage
    const { data, error } = await supabase.storage
      .from('receipts')
      .upload('receipt-example.png', blob, {
        contentType: 'image/png',
        upsert: true
      });

    if (error) throw error;

    // Get public URL
    const { data: urlData } = await supabase.storage
      .from('receipts')
      .getPublicUrl('receipt-example.png');

    return urlData.publicUrl;
  } catch (error) {
    console.error('Error uploading example receipt:', error);
    throw error;
  }
}